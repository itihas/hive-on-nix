{ stdenv
, fetchurl
, jdk
, makeWrapper
, hadoop
, maven
, bash
, coreutils
, which
, gawk
, psutils
, mysql_jdbc
, lib
}:


let mavenOld = maven.overrideAttrs
  (oldAttrs: rec {
    version = "3.6.3";
    src = fetchurl {
      url = "mirror://apache/maven/maven-3/${version}/binaries/${oldAttrs.pname}-${version}-bin.tar.gz";
      sha256 = "sha256-Jq2R11GzqaUwh676dD9OFqF3QdORWyGc90ESv4ekOMU=";
    };
  });

in
stdenv.mkDerivation
rec {

  pname = "oozie";
  version = "5.2.1";
  src = fetchurl {
    url = "mirror://apache/oozie/${version}/oozie-${version}.tar.gz";
    sha256 = "sha256-vOjCn3CsVseO/9nkCZbtrnDMa0b/rVRv8GJ0fLiDjaU=";
  };

  buildInputs = [ mavenOld ];
  nativeBuildInputs = [ jdk makeWrapper hadoop ];
  buildPhase = ''
    patchShebangs ./bin
    ./bin/mkdistro.sh -DskipTests -Dhadoop-version="3.3.1" \
    -Djava.class.path="$(${hadoop}/bin/hadoop classpath)" \
    -Dmaven.repo.local=$out
  '';
  installPhase =
    let
      untarDir = "${pname}-${version}";
    in
    ''
          find $out -type f \
      -name \*.lastUpdated -or \
      -name resolver-status.properties -or \
      -name _remote.repositories \
      -delete

      		# mkdir $out
          # cp -r ./target $out/
          # cp -r ./distro/target $out/

    '';

  outputHash = "sha256-+KFySNae1AByu82D08zWbUcfOeF0y1Xt+CDSp+L8nL4=";
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";

}
