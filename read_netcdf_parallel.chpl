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

proc CreateDomain(param numDims, indicesArr) {
  var indices: numDims*range;
  for param i in 0..<numDims do
    indices[i] = 0..#indicesArr[i];
  return {(...indices)};
}


proc DistributedRead(const filename, varid, dom_in) {

      const D = dom_in dmapped Block (dom_in);
      var dist_array : [D] real(64);

      var t : Timer;
      t.start();

      coforall loc in Locales do on loc {
        writeln("Local subdomain on Locale ", here.id, ": \n", D.localSubdomain());

        /* Some external procedure declarations */
          extern proc nc_get_vara_double(ncid : c_int, varid : c_int, startp : c_ptr(c_size_t), countp : c_ptr(c_size_t), ip : c_ptr(real(64))) : c_int;


        /* Determine where to start reading file, and how many elements to read */
          // Start specifies a hyperslab.  It expects an array of dimension sizes
          var start = tuplify(D.localSubdomain().first);
          // Count specifies a hyperslab.  It expects an array of dimension sizes
          var count = tuplify(D.localSubdomain().shape);

        /* Create arrays of c_size_t for compatibility with NetCDF-C functions. */
          var start_c = [i in 0..#start.size] start[i] : c_size_t;
          var count_c = [i in 0..#count.size] count[i] : c_size_t;

          var ncid : c_int;
          cdfError(nc_open(filename.c_str(), NC_NOWRITE, ncid));

          writeln("URL on Locale ", here.id, ": ", filename);

          nc_get_vara_double(ncid, varid, c_ptrTo(start_c), c_ptrTo(count_c), c_ptrTo(dist_array[start]));

          writeln("On locale ", here.id, " with start: ", start, ", and count:", count, ",\n", dist_array[dist_array.localSubdomain()]);
          writeln("On locale ", here.id, " read finished in ", t.elapsed(), " seconds.");

          nc_close(ncid);
      }
      //var D_sum = + reduce dist_array;
      //writeln("Sum is ", D_sum);
      //writeln("On locale ", here.id, " sum finished in ", t.elapsed(), " seconds.");
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
  // (1)  int nc_open(const char* path, int mode,     int* ncidp)
  extern proc nc_open(path : c_string, mode : c_int, ncidp : c_ptr(c_int)) : c_int;
  nc_open(filename.c_str(), NC_NOWRITE, c_ptrTo(ncid));

  // Get the variable ID
  //
  //      int nc_inq_varid(int ncid,    const char* name,      int* varidp)
  extern proc nc_inq_varid(ncid: c_int, varName: c_string, varid: c_ptr(c_int));
  nc_inq_varid(ncid, varName.c_str(), c_ptrTo(varid));

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

  var dimlens : [0..#ndims] c_size_t;

  // Get the size of each dimension
  //
  //      int nc_inq_dimlen(int ncid,     int dimid,     size_t* lenp)
  extern proc nc_inq_dimlen(ncid : c_int, dimid : c_int, lenp : c_ptr(c_size_t)) : c_int;
  for i in 0..#ndims do {
    nc_inq_dimlen(ncid, dimids[i], c_ptrTo(dimlens[i]));
  }

  writeln("dimlens: ", dimlens);
  writeln("dimlens size: ", dimlens.size);

var t : Timer;
t.start();

// Create the array to hold the data

for param p in 1..10 {
  if ndims == p {
    var dom_in = CreateDomain(p, dimlens);
    var var_dist = DistributedRead(filename, varid, dom_in);
  }
}

writeln("Took ", t.elapsed(), " seconds to do the distributed read.");
}
