import 'package:location_tracking/localDataBase/location_database.dart.dart';
import 'package:floor/floor.dart';

@dao

abstract class LocationDatabaseDao{
  @insert
  Future<int> insertLocation(Location location);

  @Query('SELECT * FROM Locations')
  Future<List<Location>?> getAllLocation();

}
