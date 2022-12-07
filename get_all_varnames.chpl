use NetCDF.C_NetCDF;

proc cdfError(e) {
  if e != NC_NOERR {
    writeln("Error: ", nc_strerror(e): string);
    exit(2);
  }
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

  writeln("ncid: ", ncid);

  // Get all variable IDs
  //
  //         int nc_inq_varids(int ncid,    int* nvars,       int* varids)	
  // extern proc nc_inq_varids(ncid: c_int, ref nvars: c_int, ref varids: c_int);
  //
  extern proc nc_inq_varids(ncid: c_int, nvars, varids);
  var nvars : c_int;
  
  nc_inq_varids(ncid, c_ptrTo(nvars), c_nil);
  
  writeln(nvars);

  var varids : [0..#nvars] c_int;

  nc_inq_varids(ncid, c_ptrTo(nvars), c_ptrTo(varids));
 
  writeln(varids);
  
  // int nc_inq_varname(int ncid, int varid, char* name)	
  extern proc nc_inq_varname(ncid : c_int, varid : c_int, name);
  for id in varids {
    var name : [0..20] c_char;
    nc_inq_varname(ncid, id, c_ptrTo(name));
    writeln((c_ptrTo(name):c_string):string );
  }
    
}



