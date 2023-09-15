https://www.census.gov/geo/maps-data/data/tiger-line.html

Due to bugs in postgis 3.1, we had to reproject the shape file from that source.

It's roughly this. As root in a container:
```
apk update
apk add gdal-tools
su - app
cd /app/shape_files/...
ogr2ogr -t_srs EPSG:4326 tl_2018_us_zcta510.reprojected.4326.shp tl_2018_us_zcta510.shp
```

and zip the resulting files into `tl_2018_us_zcta510.reprojected.4326.zip`. When
we eventually get updated zip code shapes, just pay attention to the projection
and don't blindly drop it in here. shp2pgsql can add transforms to the insert
statements, but that's what was breaking for many 1000s of zip codes on
postgres 12 with postgis 3.1.
