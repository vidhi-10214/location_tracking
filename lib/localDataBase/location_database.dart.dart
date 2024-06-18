import 'package:floor/floor.dart';

@Entity(tableName: "Locations")
class Location{
  @PrimaryKey(autoGenerate:true)
  final int? id;
  @ColumnInfo(name:'latitude')
  late final String? latitude;
  @ColumnInfo(name:'longitude')
  late final String? longitude;
  @ColumnInfo(name: 'created_at')
  final String? createdAt;

  Location({
    this.id,
    this.latitude,
    this.longitude,
    this.createdAt
   });

  @override
  String toString() {
    // TODO: implement toString
    return '{id: $id,latitude: $latitude, longitude: $longitude,created_at:$createdAt}';

  }

}
