{ clangStdenv, qt }:

clangStdenv.mkDerivation {
  pname = "nim-status-client";
  version = "0.0.1";

  src = builtins.path {
    name = "nim-status-client-source";
    path = ../;
  };
  
  buildInputs = [ qt ];

  QTDIR = qt;


}
