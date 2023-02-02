{stdenv, fetchzip, jdk, makeWrapper, hadoop
, bash, coreutils, which, gawk, psutils, mysql_jdbc
, lib
}:

stdenv.mkDerivation rec {

	pname = "oozie";
	version = "5.2.1";
  src = "./oozie-${version}-distro.tar.gz";
	buildInputs = [ ];
	nativeBuildInputs = [ mysql_jdbc jdk makeWrapper ];
	
	installPhase = let
		untarDir = "${pname}-${version}";
	in ''
        # mkdir -p $out/{share,bin,lib}
				mkdir $out
        mv * $out/
        cp ${mysql_jdbc}/share/java/mysql-connector-j.jar $out/lib

				for n in $(find $out{,/hcatalog}/bin -type f ! -name "*.*"); do
          wrapProgram "$n" \
            --set-default JAVA_HOME "${jdk.home}" \
						--set-default HIVE_HOME "$out" \
						--set-default HADOOP_HOME "${hadoop}/lib/${hadoop.untarDir}" \
            --prefix PATH : "${lib.makeBinPath [ bash coreutils which gawk psutils ]}" \
						--prefix JAVA_LIBRARY_PATH : "${lib.makeLibraryPath [ mysql_jdbc ]}" \
						--prefix HIVE_AUX_JARS_PATH : "${mysql_jdbc}/share/java/mysql-connector-j.jar"
				done
	'';
}
