import 'package:floor/floor.dart';
import 'package:location_tracking/localDataBase/location_database.dart.dart';
import 'package:location_tracking/localDataBase/location_database_dao.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart' as sqflite;
part 'database.g.dart';

@Database(version: 1,entities: [Location])
abstract class AppDatabase extends FloorDatabase{
LocationDatabaseDao get locationDatabaseDao;
}