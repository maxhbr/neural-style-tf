{pkgs ? import <nixpkgs> {}}:
with pkgs;
python35Packages.buildPythonApplication {
  name = "cysmith-neural-style-tf";
  buildInputs = [
    cudatoolkit
    cudnn
    opencv
  ] ++ (with python36Packages; [
    scikitimage
    # tensorflow
    tensorflowWithCuda
    # tensorflowWithoutCuda
    opencv
    scipy
  ]);
  shellHook = ''
    echo 'Entering Python Project Environment'
    set -v

    # extra packages can be installed here
    unset SOURCE_DATE_EPOCH
    export PIP_PREFIX="$(pwd)/pip_packages"
    python_path=(
      "$PIP_PREFIX/lib/python3.5/site-packages"
      "$PYTHONPATH"
    )
    # use double single quotes to escape bash quoting
    IFS=: eval 'python_path="''${python_path[*]}"'
    export PYTHONPATH="$python_path"
    # export MPLBACKEND='Qt4Agg'

    set +v
  '';
}
