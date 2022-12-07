use NetCDF.C_NetCDF;

// This code is based on the example pres_temp_4D_wr.c from:
// https://www.unidata.ucar.edu/software/netcdf/examples/programs/

/* This is the name of the data file we will read. */
// param filename = "snapshots_z_00000005.nc";

/* We are reading 4D data! */

// xq = 121, yh = 280, zl = 80, time = 100

/*
param ndims = 4,
      nlat = 280,
      nlon = 121,
      latName = "yh",
      lonName = "xq",
      nrec = 100,
      nlvl = 80;
*/

/* Names of things. */
//  param uName = "u";

proc cdfError(e) {
  if e != NC_NOERR {
    writeln("Error: ", nc_strerror(e): string);
    exit(2);
  }
}

proc CreateArray(param numDims, indicesArr) {

  if numDims == 1 {
    var u_in: [0..#indicesArr[0]] real(32);
    return u_in;
  } else if numDims == 2 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1]] real(32);
    return u_in;
  } else if numDims == 3 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1], 0..#indicesArr[2]] real(32);
    return u_in;
  } else if numDims == 4 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1], 0..#indicesArr[2], 0..#indicesArr[3]] real(32);
    return u_in;
  }
}

proc readData(ncid, u_varid, u_in) {

  writeln("ncid: ", ncid);
  writeln("u_varid: ", u_varid);
  // extern proc nc_get_vara_float(ncid: c_int, u_varid: c_int, ref start: c_size_t, ref count: c_size_t, ref u_in: real(32)): c_int;
  extern proc nc_get_vara_float(ncid: c_int, u_varid: c_int, start, count, u_in): c_int;

  // Start specifies a hyperslab.  It expects an array of dimension sizes
  var start = [0,0,0,0];
  // Count specifies a hyperslab.  It expects an array of dimension sizes
  var count = u_in.shape;

  writeln("count: ", count);

  cdfError( nc_get_vara_float(ncid, u_varid, c_ptrTo(start), c_ptrTo(count[0]), c_ptrTo(u_in)) );

  nc_close(ncid);

  writeln("*** SUCCESS reading example file snapshots_z_00000005.nc!");

}

proc main (args: [] string) {

  var filename = args[1].c_str();
  var varName = args[2].c_str();

  var ncid : c_int;
  var varid : c_int;
  var ndims : c_int;
  var dimid: c_int;

  // Open the file
  cdfError(nc_open(filename, NC_NOWRITE, ncid));

  // Get the variable ID
  //
  //         int nc_inq_varid(int ncid,    const char* name,      int* varidp)
  // extern proc nc_inq_varid(ncid: c_int, ref varName: c_string, ref varid: c_int);
  //
  nc_inq_varid(ncid, varName, varid);

  writeln("varid: ", varid);


  // Get the number of dimensions for this variable
  //
  //         int nc_inq_varndims(int ncid,    int varid,    int* ndimsp)
  // extern proc nc_inq_varndims(ncid: c_int, varid: c_int, ref ndims: c_int);
  //
  nc_inq_varndims(ncid, varid, ndims);

  writeln("ndims: ", ndims);

  var dimids : [0..#ndims] c_int;
  var dimlens : [0..#ndims] c_size_t;

  // Get the IDs of each dimension
  //
  //         int nc_inq_vardimid(int ncid,    int varid,    int* dimidsp)
  extern proc nc_inq_vardimid(ncid: c_int, varid: c_int, dimids);
  //
  nc_inq_vardimid(ncid, varid, c_ptrTo(dimids));

  writeln("dimids: ", dimids);

  writeln("Calculating dimlen");
  // Get the size of each dimension
  //
  // int nc_inq_dimlen	      (int ncid,    int dimid, size_t* lenp)
  extern proc nc_inq_dimlen(ncid: c_int, dimid: c_int, lenp);
  //
  for i in 0..#ndims do {
    nc_inq_dimlen(ncid, dimids[i], c_ptrTo(dimlens[i]));
  }
  writeln("Calculated dimlen");

  writeln(dimlens);

  
  // Create the array to hold the data
  if dimlens.size == 1 {
    var u_in = CreateArray(1, dimlens); // these needs to be a param value in here (so can't use runtime-known value
    writeln(u_in.shape);
    readData(ncid, varid, u_in);}
  else if dimlens.size == 2 then {
    var u_in = CreateArray(2, dimlens);
    writeln(u_in.shape);
    readData(ncid, varid, u_in);}
  else if dimlens.size == 3 then {
    var u_in = CreateArray(3, dimlens);
    writeln(u_in.shape);
    readData(ncid, varid, u_in);}
  else if dimlens.size == 4 then {
    var u_in = CreateArray(4, dimlens);
    writeln(u_in.shape);
    readData(ncid, varid, u_in);}
  





  /*
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
  cdfError(nc_inq_varid(ncid, varName, u_varid));

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
  writeln(u_in);
  writeln(u_in.domain);
  writeln(u_in.type:string);
  writeln(u_in.shape:string);
  writeln("*** SUCCESS reading example file snapshots_z_00000005.nc!");
  return 0;
  */
}

