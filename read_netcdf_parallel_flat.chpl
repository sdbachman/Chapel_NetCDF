use NetCDF.C_NetCDF;
use BlockDist;
use Time;

proc cdfError(e) {
  if e != NC_NOERR {
    writeln("Error: ", nc_strerror(e): string);
    exit(2);
  }
}

inline proc tuplify(x) {
  if isTuple(x) then return x; else return (x,);
}

proc CreateArray(param numDims, indicesArr) {

  if numDims == 1 {
    var u_in: [0..#indicesArr[0]] real(32);
    var u_flat = u_in;
    return (u_in, u_flat);
  } else if numDims == 2 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1]] real(32);
    var u_flat: [0..#(indicesArr[0] * indicesArr[1])] real(32);
    return (u_in, u_flat);
  } else if numDims == 3 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1], 0..#indicesArr[2]] real(32);
    var u_flat: [0..#(indicesArr[0] * indicesArr[1] * indicesArr[2])] real(32);
    return (u_in, u_flat);
  } else if numDims == 4 {
    var u_in: [0..#indicesArr[0], 0..#indicesArr[1], 0..#indicesArr[2], 0..#indicesArr[3]] real(32);
    var u_flat: [0..#(indicesArr[0] * indicesArr[1] * indicesArr[2] * indicesArr[3])] real(32);
    return (u_in, u_flat);
  }
}


proc DistributedRead(const filename, varid, var_in, var_flat, ndims) {

      const D = var_in.domain dmapped Block(var_in.domain);
      const D_flat = var_flat.domain dmapped Block(var_flat.domain);
      var dist_array : [D_flat] real;

      var t : Timer;
      t.start();

      coforall loc in Locales do on loc {
        writeln("Local subdomain on Locale ", here.id, ": \n", D.localSubdomain());

        /* Some external procedure declarations */
          extern proc nc_get_vara_double(ncid: c_int, u_varid: c_int, start, count, u_int): c_int;

        /* Determine where to start reading file, and how many elements to read */
          // Start specifies a hyperslab.  It expects an array of dimension sizes
          var start = tuplify(D.localSubdomain().first);
          var start_flat = tuplify(D_flat.localSubdomain().first);
          // Count specifies a hyperslab.  It expects an array of dimension sizes
          var count = tuplify(D.localSubdomain().shape);

        /* Create arrays of c_size_t for compatibility with NetCDF-C functions. */
          var start_c = [i in 0..#start.size] start[i] : c_size_t;
          var count_c = [i in 0..#count.size] count[i] : c_size_t;

          var ncid : c_int;
          cdfError(nc_open(filename.c_str(), NC_NOWRITE, ncid));

          writeln("URL on Locale ", here.id, ": ", filename);

          nc_get_vara_double(ncid, varid, c_ptrTo(start_c[0]), c_ptrTo(count_c[0]), c_ptrTo(dist_array[start_flat]));

          writeln("On locale ", here.id, " with start: ", start, ", and count:", count, ",\n", dist_array[dist_array.localSubdomain()]);
          writeln("On locale ", here.id, " read finished in ", t.elapsed(), " seconds.");

          nc_close(ncid);
      }
      var D_sum = + reduce dist_array;
      writeln("Sum is ", D_sum);
      writeln("On locale ", here.id, " sum finished in ", t.elapsed(), " seconds.");
      return dist_array;

    }


proc main (args: [] string) {

  var filename = args[1];
  var varName = args[2];

  var ncid : c_int;
  var varid : c_int;
  var ndims : c_int;
  var dimid: c_int;

  // Open the file
  cdfError(nc_open(filename.c_str(), NC_NOWRITE, ncid));

  // Get the variable ID
  //
  //         int nc_inq_varid(int ncid,    const char* name,      int* varidp)
  // extern proc nc_inq_varid(ncid: c_int, ref varName: c_string, ref varid: c_int);
  //
  nc_inq_varid(ncid, varName.c_str(), varid);

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

  // Get the size of each dimension
  //
  // int nc_inq_dimlen	      (int ncid,    int dimid, size_t* lenp)
  extern proc nc_inq_dimlen(ncid: c_int, dimid: c_int, lenp);
  //
  for i in 0..#ndims do {
    nc_inq_dimlen(ncid, dimids[i], c_ptrTo(dimlens[i]));
  }

  writeln("dimlens: ", dimlens);
  writeln("dimlens size: ", dimlens.size);

var t : Timer;
t.start();

// Create the array to hold the data

        if dimlens.size == 1 {
          var (var_in, var_flat) = CreateArray(1, dimlens);  // these needs to be a param value in here (so can't use runtime-known value
          var var_dist = DistributedRead(filename, varid, var_in, var_flat, ndims);}
        else if dimlens.size == 2 then {
          var (var_in, var_flat) = CreateArray(2, dimlens);
          var var_dist = DistributedRead(filename, varid, var_in, var_flat, ndims);}
        else if dimlens.size == 3 then {
          var (var_in, var_flat) = CreateArray(3, dimlens);
          var var_dist = DistributedRead(filename, varid, var_in, var_flat, ndims);}
        else if dimlens.size == 4 then {
          var (var_in, var_flat) = CreateArray(4, dimlens);
          var var_dist = DistributedRead(filename, varid, var_in, var_flat, ndims);
        }

writeln("Took ", t.elapsed(), " seconds to do the distributed read.");
}
