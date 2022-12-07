use NetCDF.C_NetCDF;

// This code is based on the example pres_temp_4D_wr.c from:
// https://www.unidata.ucar.edu/software/netcdf/examples/programs/

/* This is the name of the data file we will read. */
param filename = "snapshots_z_00000005.nc";

/* We are reading 4D data! */

// xq = 121, yh = 280, zl = 80, time = 100
param ndims = 4,
      nlat = 280,
      nlon = 121,
      latName = "yh",
      lonName = "xq",
      nrec = 100,
      nlvl = 80;

/* Names of things. */
  param uName = "u";

proc cdfError(e) {
  if e != NC_NOERR {
    writeln("Error: ", nc_strerror(e): string);
    exit(2);
  }
}

proc main {
  var ncid: c_int;
  var u_varid : c_int;
  var lat_varid, lon_varid: c_int;

  /* The start and count arrays will tell the netCDF library where to
     read our data. */
  var start, count: [0..#ndims] c_size_t;

  /* Program variables to hold the data we will read. */
  var u_in : [0..#nrec, 0..#nlvl, 0..#nlat, 0..#nlon] real(32);

  /* These program variables hold the latitudes and longitudes. */
  var lats: [0..#nlat] real(32),
      lons: [0..#nlon] real(32);

  /* Loop indexes. */
  var lvl, lat, lon, rec, i = 0;

  /* Open the file. */
  cdfError(nc_open(filename, NC_NOWRITE, ncid));

  /* Get the varids of the latitude and longitude coordinate
   * variables. */
  cdfError(nc_inq_varid(ncid, latName, lat_varid));
  cdfError(nc_inq_varid(ncid, lonName, lon_varid));

  /* Read the coordinate variable data. */
  cdfError(nc_get_var_float(ncid, lat_varid, lats[0]));
  cdfError(nc_get_var_float(ncid, lon_varid, lons[0]));

  /* Get the varids of the netCDF variables. */
  cdfError(nc_inq_varid(ncid, uName, u_varid));

  /* Read the data. */
  count[0] = nrec;
  count[1] = nlvl;
  count[2] = nlat;
  count[3] = nlon;
  // These give us control over where we start reading from the file
  start[0] = 0;
  start[1] = 0;
  start[2] = 0;
  start[3] = 0;


    extern proc nc_get_vara_float(ncid: c_int, u_varid: c_int, ref start: c_size_t, ref count: c_size_t, ref u_in: real(32)): c_int;

    cdfError(nc_get_vara_float(ncid, u_varid, start[0],
                                   count[0], u_in[0, 0, 0, 0]));





  /* Close the file. */
  cdfError(nc_close(ncid));

  writeln("Pres_in: ");
  writeln(u_in[1,1,1..10,1..10]);
  writeln(u_in.domain);
  writeln(u_in.type:string);
  writeln(u_in.shape:string);
  writeln("*** SUCCESS reading example file snapshots_z_00000005.nc!");
  return 0;
}

