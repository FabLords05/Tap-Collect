import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true);
  try {
    env.load();
  } catch (e) {
    print("⚠️ .env file not found, using defaults");
  }

  final mongoUri = env['MONGO_URI'] ?? 'mongodb://127.0.0.1:27017/groove_nfcDB';
  
  print('🔄 Connecting to Database...');
  final db = await Db.create(mongoUri);
  await db.open();

  final usersCol = db.collection('users');

  // 1. Count how many need fixing
  final count = await usersCol.count(where.notExists('points_balance'));
  print('found $count users with missing points_balance.');

  if (count > 0) {
    // 2. Update them all
    print('🛠️  Fixing users...');
    
    // Update all documents where 'points_balance' does not exist
    // Set it to 0
    await usersCol.update(
      where.notExists('points_balance'),
      modify.set('points_balance', 0),
      multiUpdate: true // Important! Update ALL of them, not just the first one
    );
    
    print('✅ Successfully updated $count users. They now have 0 points.');
  } else {
    print('✅ All users already have points data. No action needed.');
  }

  await db.close();
  exit(0);
}