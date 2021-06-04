with import <nixpkgs> { };

runCommand "dummy" 
{
   buildInputs = [ kubernetes-helm ]; 
} ""