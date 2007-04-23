echo Before release:
echo -- increment version
echo -- update version info in release/README.txt and release/doc/skij.html
echo -- compile everything
echo -- make javadoc (makeskijdoc.bat)
echo -- build new autoload table
echo -- compile libraries?


rem - copy stuff for binary JAR
cd d:\mt\release\com\ibm\jikes
rem - DANGER WILL ROBINSON
rm -r *
mkdir skij
cp d:/java/misc/com/ibm/jikes/skij/*.class skij
cd skij
mkdir misc
cp d:/java/misc/com/ibm/jikes/skij/misc/*.class misc
cp d:/java/misc/com/ibm/jikes/skij/misc/*.txt misc
mkdir util
cp d:/java/misc/com/ibm/jikes/skij/util/*.class util
mkdir lib
cp d:/java/misc/com/ibm/jikes/skij/lib/*.scm lib
cp d:/java/misc/com/ibm/jikes/skij/lib/*.class lib

rem - make inner jar file (binary)
rm d:\mt\skij\release\skij.jar
cd d:\mt\release
jar cvf0 d:\mt\skij\release\skij.jar com\*

rem make a cab file too
rem F:\downloads\cab-sdk\bin\cabarc -r -p N d:\mt\skij\release\skij.cab com\*

rem - make source JAR
cd d:\mt\release\com\ibm\jikes
rm -r *
mkdir skij
cp d:/java/misc/com/ibm/jikes/skij/*.java skij
cd skij
mkdir misc
cp d:/java/misc/com/ibm/jikes/skij/misc/*.java misc
mkdir util
cp d:/java/misc/com/ibm/jikes/skij/util/*.java util

rm d:\mt\skij\release\skijsrc.jar
cd d:\mt\release
jar cvf0 d:\mt\skij\release\skijsrc.jar com\*


rem - make dist zip file
cd d:\mt\skij\release
rm d:\mt\release\skijpkg.zip
clean
jar cvfM d:\mt\release\skijpkg.zip *

echo Done!


