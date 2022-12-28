use NetCDF.C_NetCDF;
use Time;

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
    var u_in: [0..#indicesArr[0]] real(64);
    return u_in;
  } else if numDims == 2 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1]] real(64);
    return u_in;
  } else if numDims == 3 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1], 0..#indicesArr[2]] real(64);
    return u_in;
  } else if numDims == 4 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1], 0..#indicesArr[2], 0..#indicesArr[3]] real(64);
    return u_in;
  }
}

proc readData(ncid, u_varid, u_in) {

  var t : Timer;
  t.start(); 

  writeln("ncid: ", ncid);
  writeln("u_varid: ", u_varid);
  //         int nc_get_vara_double(int ncid,     int varid,     const size_t* startp,  const size_t* countp,  double* ip)	
  // extern proc nc_get_vara_double(ncid : c_int, varid : c_int, ref startp : c_size_t, ref countp : c_size_t, ref ip : c_double) : c_int;
  ////extern proc nc_get_vara_double(ncid: c_int, u_varid: c_int, start, count, u_in): c_int;
  extern proc nc_get_vara_double(ncid : c_int, varid : c_int, startp : c_ptr(c_size_t), countp : c_ptr(c_size_t), ip : c_ptr(real(64))) : c_int;

  // Start specifies a hyperslab.  It expects an array of dimension sizes
  var start = [0,0,0,0];
  // Count specifies a hyperslab.  It expects an array of dimension sizes
  var count = u_in.shape;

  var start_c = [i in 0..#start.size] start[i] : c_size_t;
  var count_c = [i in 0..#count.size] count[i] : c_size_t;

  writeln("count: ", count);

  nc_get_vara_double(ncid, u_varid, c_ptrTo(start_c), c_ptrTo(count_c), c_ptrTo(u_in));

  nc_close(ncid);

  writeln("On locale ", here.id, " read finished in ", t.elapsed(), " seconds.");
  writeln("*** SUCCESS reading example file snapshots_z_00000005.nc!");
  writeln(u_in);
}

proc main (args: [] string) {

  var filename = args[1].c_str();
  var varName = args[2].c_str();

  var ncid : c_int;
  var varid : c_int;
  var ndims : c_int;
  var dimid: c_int;

  // Open the file
  // (1)  int nc_open(const char* path, int mode,     int* ncidp)
  extern proc nc_open(path : c_string, mode : c_int, ncidp : c_ptr(c_int)) : c_int;
  nc_open(filename, NC_NOWRITE, c_ptrTo(ncid));

  // Get the variable ID
  //
  //      int nc_inq_varid(int ncid,    const char* name,      int* varidp)
  extern proc nc_inq_varid(ncid: c_int, varName: c_string, varid: c_ptr(c_int));
  nc_inq_varid(ncid, varName, c_ptrTo(varid));

  writeln("varid: ", varid);


  // Get the number of dimensions for this variable
  //
  //      int nc_inq_varndims(int ncid,    int varid,    int* ndimsp)
  extern proc nc_inq_varndims(ncid: c_int, varid: c_int, ndims: c_ptr(c_int));
  nc_inq_varndims(ncid, varid, c_ptrTo(ndims));

  writeln("ndims: ", ndims);

  var dimids : [0..#ndims] c_int;

  // Get the IDs of each dimension
  //
  //      int nc_inq_vardimid(int ncid,     int varid,     int* dimidsp)
  extern proc nc_inq_vardimid(ncid : c_int, varid : c_int, dimidsp : c_ptr(c_int)) : c_int;

  nc_inq_vardimid(ncid, varid, c_ptrTo(dimids));

  writeln("dimids: ", dimids);

  writeln("Calculating dimlen");

  var dimlens : [0..#ndims] c_size_t;

  // Get the size of each dimension
  //
  //         int nc_inq_dimlen(int ncid,     int dimid,     size_t* lenp)
  // extern proc nc_inq_dimlen(ncid : c_int, dimid : c_int, ref lenp : c_size_t) : c_int;
  ////extern proc nc_inq_dimlen(ncid: c_int, dimid: c_int, lenp);
  //
  extern proc nc_inq_dimlen(ncid : c_int, dimid : c_int, lenp : c_ptr(c_size_t)) : c_int;
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
  


}
