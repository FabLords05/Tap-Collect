import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// --- Helper Functions ---
String? _idFromInsertResult(dynamic res, Map<String, dynamic> doc) {
  try {
    if (res == null) return doc['_id']?.toString();
    final dynamic idProp = (res is Map && res.containsKey('insertedId'))
        ? res['insertedId']
        : (res is Map && res.containsKey('id'))
            ? res['id']
            : (res is Object)
                ? (res as dynamic).id
                : null;
    if (idProp != null) return idProp.toString();
  } catch (_) {}
  return doc['_id']?.toString();
}

Map<String, dynamic> _mapDoc(Map<String, dynamic> d) {
  final map = Map<String, dynamic>.from(d);
  if (d.containsKey('_id')) {
    map['id'] = d['_id']?.toString();
    map.remove('_id');
  }
  return map;
}

String _titleCase(String? input) {
  if (input == null) return '';
  return input
      .split(RegExp(r"\s+"))
      .where((s) => s.isNotEmpty)
      .map((word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');
}

String _normalizeEmail(String? input) => (input ?? '').trim().toLowerCase();

// --- Main Server Function ---
void main(List<String> args) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final mongoUri = env['MONGO_URI'] ?? 'mongodb://127.0.0.1:27017/groove_nfcDB';
  final portStr = env['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;

  stderr.writeln('Connecting to MongoDB: $mongoUri');

  final db = await Db.create(mongoUri);
  try {
    await db.open();
    stderr.writeln('Connected to MongoDB');
  } catch (e) {
    stderr.writeln('MongoDB connection failed: $e');
    exit(1);
  }

  final usersCol = db.collection('users');
  final businessesCol = db.collection('businesses');
  final merchantsCol = db.collection('merchants');
  final rewardsCol = db.collection('rewards');
  final vouchersCol = db.collection('vouchers');
  final transactionsCol = db.collection('transactions');

  final router = Router();

  router.get('/health', (_) => Response.ok(jsonEncode({'status': 'ok'})));

  // --- AUTH: REGISTER ---
  router.post('/auth/register', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['email'] == null ||
        data['name'] == null ||
        data['password'] == null) {
      return Response(400,
          body: jsonEncode({'error': 'email, name, and password required'}));
    }

    final email = _normalizeEmail(data['email'] as String?);
    final name = _titleCase(data['name'] as String?);

    final existing = await usersCol.findOne(where.eq('email', email));
    if (existing != null) {
      return Response(409, body: jsonEncode({'error': 'email exists'}));
    }

    final now = DateTime.now().toIso8601String();
    final doc = {
      'email': email,
      'name': name,
      'password': data['password'],
      'avatar': data['avatar'] ?? 'default.png',
      'points_balance': 0, // Initialize wallet
      'activated_business_ids': [],
      'created_at': now,
      'updated_at': now,
    };

    final res = await usersCol.insertOne(doc);
    final id = _idFromInsertResult(res, doc);
    final result = Map<String, dynamic>.from(doc);

    result.remove('password');
    if (id != null) result['id'] = id;

    return Response(201, body: jsonEncode(result));
  });

  // --- AUTH: LOGIN ---
  router.post('/auth/login', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['email'] == null || data['password'] == null) {
      return Response(400,
          body: jsonEncode({'error': 'email and password required'}));
    }

    final email = _normalizeEmail(data['email'] as String?);
    final user = await usersCol.findOne(where.eq('email', email));

    if (user == null || user['password'] != data['password']) {
      return Response(401,
          body: jsonEncode({'error': 'Invalid email or password'}));
    }

    final result = _mapDoc(user);
    result.remove('password');
    return Response.ok(jsonEncode(result));
  });

  // --- USERS ROUTES ---
  router.get('/users', (_) async {
    final docs = await usersCol.find().toList();
    final result = docs.map((d) {
      var map = _mapDoc(Map<String, dynamic>.from(d));
      map.remove('password');
      return map;
    }).toList();
    return Response.ok(jsonEncode(result));
  });

  router.get('/users/<id>', (req, String id) async {
    try {
      final objId = ObjectId.parse(id);
      final user = await usersCol.findOne(where.eq('_id', objId));
      if (user == null) {
        return Response.notFound(jsonEncode({'error': 'not found'}));
      }
      final result = _mapDoc(user);
      result.remove('password');
      return Response.ok(jsonEncode(result));
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'invalid id'}));
    }
  });

  router.patch('/users/<id>', (req, String id) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final objId = ObjectId.parse(id);

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String()
      };

      if (data.containsKey('activated_business_ids')) {
        updateData['activated_business_ids'] = data['activated_business_ids'];
      }
      if (data.containsKey('name')) updateData['name'] = data['name'];
      if (data.containsKey('avatar')) updateData['avatar'] = data['avatar'];

      // FIX: Use raw $set map instead of modify.setAll (which doesn't exist)
      await usersCol.updateOne(where.eq('_id', objId), {r'$set': updateData});

      return Response.ok(jsonEncode({'status': 'updated'}));
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'update failed'}));
    }
  });

  // --- TRANSACTIONS (Points Logic) ---
  // Create transaction (replace existing /transactions handler)
  router.post('/transactions', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['user_id'] == null ||
        data['business_id'] == null ||
        data['type'] == null) {
      return Response(400,
          body: jsonEncode({'error': 'user_id, business_id, type required'}));
    }

    final String userIdStr = data['user_id'] as String;
    final String businessId = data['business_id'] as String;
    final String type = (data['type'] as String).toUpperCase();

    // compute points: prefer explicit 'points', else use amount_spent * business.points_per_dollar, else 1
    int points = 0;
    if (data.containsKey('points')) {
      points = (data['points'] is num)
          ? (data['points'] as num).toInt()
          : int.tryParse('${data['points']}') ?? 0;
    } else if (data.containsKey('amount_spent')) {
      final amt = double.tryParse('${data['amount_spent']}') ?? 0.0;
      final biz = await businessesCol.findOne(
          where.eq('_id', ObjectId.tryParse(businessId) ?? businessId));
      final ppd = (biz != null && biz['points_per_dollar'] != null)
          ? (double.tryParse('${biz['points_per_dollar']}') ?? 1.0)
          : 1.0;
      points = (amt * ppd).floor();
    } else {
      // default fallback if no amount/points: award 1 point per tap
      points = 1;
    }

    if (points < 0) {
      return Response(400, body: jsonEncode({'error': 'points must be >= 0'}));
    }

    final now = DateTime.now().toIso8601String();
    final doc = {
      'user_id': userIdStr,
      'business_id': businessId,
      'type': type,
      'points': points,
      'description': data['description'] ?? 'Tap NFC',
      'reward_id': data['reward_id'],
      'created_at': now,
    };

    // Insert transaction first (so we keep a record even if balance update fails)
    await transactionsCol.insertOne(doc);
    print("✅ Transaction saved: $points points");

    // Try to update user's balance atomically
    try {
      // resolve ObjectId if possible
      final userObjId = ObjectId.tryParse(userIdStr);
      final selector = userObjId != null
          ? where.eq('_id', userObjId)
          : where.eq('_id', userIdStr);

      if (type == 'REDEEM') {
        // ensure balance won't go negative: use findOneAndUpdate-like pattern if driver supports it,
        // otherwise check then update (best-effort)
        final userDoc = await usersCol.findOne(selector);
        if (userDoc == null) {
          return Response(404, body: jsonEncode({'error': 'user not found'}));
        }
        final current = (userDoc['points_balance'] is num)
            ? (userDoc['points_balance'] as num).toInt()
            : 0;
        if (current < points) {
          return Response(400,
              body: jsonEncode(
                  {'error': 'insufficient points', 'balance': current}));
        }
      }

      // atomic increment (works for EARN and REDEEM if REDEEM uses negative points)
      final incValue = (type == 'REDEEM') ? -points : points;
      await usersCol.updateOne(
          selector, modify.inc('points_balance', incValue));

      // return the updated balance
      final updatedUser = await usersCol.findOne(selector);
      final newBalance =
          (updatedUser != null && updatedUser['points_balance'] != null)
              ? updatedUser['points_balance']
              : 0;
      final result = Map<String, dynamic>.from(doc);
      result['id'] = _idFromInsertResult(null, doc) ?? '';
      result['new_balance'] = newBalance;
      return Response(201, body: jsonEncode(result));
    } catch (e) {
      // log and return error but transaction record stays for audit
      stderr.writeln('Error updating points balance: $e');
      return Response(500,
          body: jsonEncode({'error': 'failed to update balance'}));
    }
  });

  router.get('/users/<user_id>/transactions', (req, String userId) async {
    final docs =
        await transactionsCol.find(where.eq('user_id', userId)).toList();
    final result =
        docs.map((d) => _mapDoc(Map<String, dynamic>.from(d))).toList();
    return Response.ok(jsonEncode(result));
  });

  // --- BUSINESS ROUTES ---
  router.get('/businesses', (_) async {
    final docs = await businessesCol.find().toList();
    final result =
        docs.map((d) => _mapDoc(Map<String, dynamic>.from(d))).toList();
    return Response.ok(jsonEncode(result));
  });

  router.post('/businesses', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['name'] == null || data['address'] == null) {
      return Response(400,
          body: jsonEncode({'error': 'name and address required'}));
    }

    final now = DateTime.now().toIso8601String();
    final doc = {
      'name': _titleCase(data['name'] as String?),
      'description': data['description'],
      'logo_url': data['logo_url'],
      'address': data['address'],
      'phone': data['phone'],
      'email': _normalizeEmail(data['email'] as String?),
      'points_per_dollar': data['points_per_dollar'] ?? 1,
      'created_at': now,
      'updated_at': now,
    };

    final res = await businessesCol.insertOne(doc);
    final id = _idFromInsertResult(res, doc);
    final result = Map<String, dynamic>.from(doc);
    if (id != null) result['id'] = id;

    return Response(201, body: jsonEncode(result));
  });

  router.get('/businesses/<id>', (req, String id) async {
    try {
      final objId = ObjectId.parse(id);
      final doc = await businessesCol.findOne(where.eq('_id', objId));
      if (doc == null)
        return Response.notFound(jsonEncode({'error': 'not found'}));
      final result = _mapDoc(doc);
      return Response.ok(jsonEncode(result));
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'invalid id'}));
    }
  });

  // --- MERCHANT ROUTES ---
  router.post('/merchants', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['email'] == null ||
        data['name'] == null ||
        data['business_id'] == null) {
      return Response(400,
          body: jsonEncode({'error': 'email, name, business_id required'}));
    }

    final now = DateTime.now().toIso8601String();
    final doc = {
      'email': _normalizeEmail(data['email'] as String?),
      'name': _titleCase(data['name'] as String?),
      'business_id': data['business_id'],
      'created_at': now,
      'updated_at': now,
    };

    final res = await merchantsCol.insertOne(doc);
    final id = _idFromInsertResult(res, doc);
    final result = Map<String, dynamic>.from(doc);
    if (id != null) result['id'] = id;

    return Response(201, body: jsonEncode(result));
  });

  router.get('/merchants/business/<business_id>',
      (req, String businessId) async {
    final docs =
        await merchantsCol.find(where.eq('business_id', businessId)).toList();
    final result =
        docs.map((d) => _mapDoc(Map<String, dynamic>.from(d))).toList();
    return Response.ok(jsonEncode(result));
  });

  // --- REWARD ROUTES ---
  router.get('/businesses/<business_id>/rewards',
      (req, String businessId) async {
    final docs =
        await rewardsCol.find(where.eq('business_id', businessId)).toList();
    final result =
        docs.map((d) => _mapDoc(Map<String, dynamic>.from(d))).toList();
    return Response.ok(jsonEncode(result));
  });

  router.post('/rewards', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['business_id'] == null ||
        data['title'] == null ||
        data['points_cost'] == null) {
      return Response(400,
          body: jsonEncode(
              {'error': 'business_id, title, points_cost required'}));
    }

    final now = DateTime.now().toIso8601String();
    final doc = {
      'business_id': data['business_id'],
      'title': data['title'],
      'description': data['description'],
      'points_cost': data['points_cost'],
      'image_url': data['image_url'],
      'is_active': data['is_active'] ?? true,
      'expires_at': data['expires_at'],
      'created_at': now,
      'updated_at': now,
    };

    final res = await rewardsCol.insertOne(doc);
    final id = _idFromInsertResult(res, doc);
    final result = Map<String, dynamic>.from(doc);
    if (id != null) result['id'] = id;

    return Response(201, body: jsonEncode(result));
  });

  // --- VOUCHER ROUTES ---
  router.get('/vouchers', (_) async {
    final docs = await vouchersCol.find().toList();
    final result =
        docs.map((d) => _mapDoc(Map<String, dynamic>.from(d))).toList();
    return Response.ok(jsonEncode(result));
  });

  router.get('/users/<user_id>/vouchers', (req, String userId) async {
    final docs = await vouchersCol.find(where.eq('user_id', userId)).toList();
    final result =
        docs.map((d) => _mapDoc(Map<String, dynamic>.from(d))).toList();
    return Response.ok(jsonEncode(result));
  });

  router.post('/vouchers', (req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (data['user_id'] == null ||
        data['reward_id'] == null ||
        data['code'] == null) {
      return Response(400,
          body: jsonEncode({'error': 'user_id, reward_id, code required'}));
    }

    final now = DateTime.now().toIso8601String();
    final doc = {
      'user_id': data['user_id'],
      'reward_id': data['reward_id'],
      'code': data['code'],
      'status': data['status'] ?? 'active',
      'expires_at': data['expires_at'],
      'redeemed_at': data['redeemed_at'],
      'created_at': now,
      'updated_at': now,
    };

    final res = await vouchersCol.insertOne(doc);
    final id = _idFromInsertResult(res, doc);
    final result = Map<String, dynamic>.from(doc);
    if (id != null) result['id'] = id;

    return Response(201, body: jsonEncode(result));
  });

  router.patch('/vouchers/<id>', (req, String id) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final objId = ObjectId.parse(id);
      final now = DateTime.now().toIso8601String();

      final updateMap = {'updated_at': now};
      if (data['status'] != null) updateMap['status'] = data['status'];
      if (data['redeemed_at'] != null)
        updateMap['redeemed_at'] = data['redeemed_at'];

      // FIX: Use raw $set map instead of modify.setAll
      await vouchersCol.updateOne(where.eq('_id', objId), {r'$set': updateMap});
      final updated = await vouchersCol.findOne(where.eq('_id', objId));

      if (updated == null)
        return Response.notFound(jsonEncode({'error': 'not found'}));
      final result = _mapDoc(updated);
      return Response.ok(jsonEncode(result));
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'invalid id'}));
    }
  });

  router.delete('/vouchers/<id>', (req, String id) async {
    try {
      final objId = ObjectId.parse(id);
      await vouchersCol.deleteOne(where.eq('_id', objId));
      final still = await vouchersCol.findOne(where.eq('_id', objId));
      return Response.ok(jsonEncode({'deleted': still == null}));
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'invalid id'}));
    }
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware)
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stderr.writeln('Server listening on port ${server.port}');
}

Handler _corsMiddleware(Handler innerHandler) {
  return (Request request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: {
        'access-control-allow-origin': '*',
        'access-control-allow-methods':
            'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'access-control-allow-headers':
            'Origin, Content-Type, Accept, Authorization',
      });
    }
    final resp = await innerHandler(request);
    return resp.change(headers: {
      ...resp.headers,
      'access-control-allow-origin': '*',
      'content-type': 'application/json',
    });
  };
}
