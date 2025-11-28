import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  // 1. Safe Environment Loading
  var env = DotEnv(includePlatformEnvironment: true);
  try {
    env.load(); 
  } catch (e) {
    print("⚠️ .env file not found (using defaults)");
  }
  
  // Use 127.0.0.1 for local development
  final mongoUri = env['MONGO_URI'] ?? 'mongodb://127.0.0.1:27017/groove_nfcDB';

  print('🌱 Connecting to: $mongoUri');

  final db = await Db.create(mongoUri);
  try {
    await db.open();
  } catch (e) {
    print('❌ Connection Failed: $e');
    print('Make sure MongoDB is running!');
    exit(1);
  }

  final usersCol = db.collection('users');
  final transactionsCol = db.collection('transactions');

  print('🌱 Seeding History Data...');

  // 2. Create a User with a BROKEN Balance (0)
  // We intentionally give them 0 points to prove our aggregation works later
  final userId = ObjectId();
  await usersCol.insertOne({
    '_id': userId,
    'name': 'History Hero',
    'email': 'history@test.com',
    'password': 'password123',
    'avatar': 'default.png',
    'points_balance': 0, // <--- INTENTIONALLY WRONG! 
    'activated_business_ids': [],
    'created_at': DateTime.now().toIso8601String(),
  });
  
  print('👤 User Created: History Hero (ID: ${userId.toHexString()})');
  print('⚠️  Current Balance set to: 0 (Incorrect)');

  // 3. Create the History (The Truth)
  // Total should be: 100 + 50 + 50 - 20 = 180
  final history = [
    {'points': 100, 'type': 'EARN', 'desc': 'Welcome Bonus'},
    {'points': 50, 'type': 'EARN', 'desc': 'Coffee Purchase'},
    {'points': 50, 'type': 'EARN', 'desc': 'Lunch Special'},
    {'points': -20, 'type': 'REDEEM', 'desc': 'Cookie Reward'}, // Negative!
  ];

  for (var item in history) {
    await transactionsCol.insertOne({
      'user_id': userId.toHexString(),
      'business_id': 'sample-biz',
      'type': item['type'],
      'points': item['points'], 
      'description': item['desc'],
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  print('📜 Added ${history.length} transactions.');
  print('👉 Now run the aggregation endpoint to fix the balance!');

  await db.close();
  exit(0);
}