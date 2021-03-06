{stdenv, fetchurl, jdk, makeWrapper, hadoop
, bash, coreutils, which, gawk, psutils, mysql_jdbc
, lib
}:

stdenv.mkDerivation rec {

	pname = "hive";
	version = "2.3.9";
	src = fetchurl {
		url = "mirror://apache/hive/hive-${version}/apache-hive-${version}-bin.tar.gz";
		sha256 = "sha256-GZYyfJZnLn6o6qj8Y5csdbwJUoejJhLlReDlHBYiy1w=";
	};
	
	buildInputs = [ mysql_jdbc ];
	nativeBuildInputs = [ jdk makeWrapper ];
	
	installPhase = let
		untarDir = "${pname}-${version}";
	in ''
        # mkdir -p $out/{share,bin}
				mkdir $out
        mv * $out/

				for n in $(find $out{,/hcatalog}/bin -type f ! -name "*.*"); do
          wrapProgram "$n" \
            --set-default JAVA_HOME "${jdk.home}" \
						--set-default HIVE_HOME "$out" \
						--set-default HADOOP_HOME "${hadoop}/lib/${hadoop.untarDir}" \
            --prefix PATH : "${lib.makeBinPath [ bash coreutils which gawk psutils ]}" \
						--prefix JAVA_LIBRARY_PATH : "${lib.makeLibraryPath [ mysql_jdbc ]}" \
						--prefix HIVE_AUX_JARS_PATH : "${mysql_jdbc}/share/java/mysql-connector-java.jar"
				done
	'';
}
