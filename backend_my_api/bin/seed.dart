import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  // 1. Load Environment Variables
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final mongoUri = env['MONGO_URI'] ?? 'mongodb://127.0.0.1:27017/groove_nfcDB';

  print('🌱 Seeding Database at: $mongoUri');

  final db = await Db.create(mongoUri);
  await db.open();

  // 2. Define Collections
  final businessesCol = db.collection('businesses');
  final merchantsCol = db.collection('merchants');
  final rewardsCol = db.collection('rewards');
  final transactionsCol = db.collection('transactions');
  final vouchersCol = db.collection('vouchers');

  // 3. Clear old data (Optional: Be careful with this in production!)
  await businessesCol.drop();
  await merchantsCol.drop();
  await rewardsCol.drop();
  await transactionsCol.drop();
  await vouchersCol.drop();
  print('🗑️  Old data cleared.');

  // ---------------------------------------------------------
  // 4. Create a Sample Business
  // ---------------------------------------------------------
  final businessId = ObjectId(); // Generate ID manually so we can link it
  
  await businessesCol.insertOne({
    '_id': businessId,
    'name': 'Grove Cafe',
    'description': 'The best coffee in the neighborhood.',
    'logo_url': 'https://placehold.co/200x200/png', // Placeholder image
    'address': '123 Main Street, Tech City',
    'phone': '555-0199',
    'email': 'contact@grovecafe.com',
    'points_per_dollar': 10, // Spend $1, get 10 points
    'created_at': DateTime.now().toIso8601String(),
  });
  print('✅ Business Created: Grove Cafe');


  

  // ---------------------------------------------------------
  // 5. Create a Merchant (Staff) for that Business
  // ---------------------------------------------------------
  await merchantsCol.insertOne({
    'name': 'Barista Mike',
    'email': 'mike@grovecafe.com',
    'password': 'password123', // In real app, hash this!
    'business_id': businessId.toHexString(), // LINK TO CAFE
    'role': 'manager',
    'created_at': DateTime.now().toIso8601String(),
  });
  print('✅ Merchant Created: Barista Mike');

  // ---------------------------------------------------------
  // 6. Create Rewards for that Business
  // ---------------------------------------------------------
  await rewardsCol.insertMany([
    {
      'business_id': businessId.toHexString(), // LINK TO CAFE
      'title': 'Free Espresso',
      'description': 'A shot of our finest beans.',
      'points_cost': 50,
      'image_url': 'https://placehold.co/100x100/png',
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'business_id': businessId.toHexString(), // LINK TO CAFE
      'title': 'Free Pastry',
      'description': 'Any croissant or muffin.',
      'points_cost': 100,
      'image_url': 'https://placehold.co/100x100/png',
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    }
  ]);
  print('✅ Rewards Created: Espresso & Pastry');
  
// ---------------------------------------------------------
  // 7. Create a Dummy Transaction (History)
  // ---------------------------------------------------------
  // We need a user ID first. In a real seed, we might create a user too.
  // For now, let's just create a placeholder transaction.
  
  await transactionsCol.insertOne({
    'user_id': 'placeholder_user_id',
    'business_id': businessId.toHexString(),
    'type': 'EARN',
    'points': 500,
    'description': 'Welcome Bonus (Seeded)',
    'created_at': DateTime.now().toIso8601String(),
  });
  print('✅ Transaction Created');

  // ---------------------------------------------------------
  // 8. Create a Dummy Voucher
  // ---------------------------------------------------------
  await vouchersCol.insertOne({
    'user_id': 'placeholder_user_id',
    'reward_id': 'placeholder_reward_id',
    'code': 'WELCOME-GIFT-2025',
    'status': 'ACTIVE',
    'created_at': DateTime.now().toIso8601String(),
  });
  print('✅ Voucher Created');

  // 9. Close Connection
  print('🎉 Database Seeded Successfully!');
  await db.close();
  exit(0);
}