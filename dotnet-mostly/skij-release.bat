echo Before release:
echo -- increment version
echo -- update version info in release/README.txt and release/doc/skij.html
echo -- compile everything
echo -- make javadoc (makeskijdoc.bat)
echo -- build new autoload table
echo -- compile libraries?


rem - copy
rm -r d:/mt/release/com/ibm/jikes/skij
cp -r d:/java/misc/com/ibm/jikes/skij d:/mt/release/com/ibm/jikes

rem - clean
cd d:\mt\release\com\ibm\jikes\skij
rm -r scm
rm -r mt
rm -r brules
rm lib/*.java
clean


rem - make inner jar file 
rm d:\mt\skij\release\skij.jar
cd d:\mt\release
jar cvf0 d:\mt\skij\release\skij.jar com\*

rem make a cab file too
rem F:\downloads\cab-sdk\bin\cabarc -r -p N d:\mt\skij\release\skij.cab com\*

rem - make dist zip file
cd d:\mt\skij\release
rm d:\mt\release\skijpkg.zip
clean
jar cvfM d:\mt\release\skijpkg.zip *

rem OPTIONAL operations to make skijlet file (no source)
cd d:\mt\release\com\ibm\jikes\skij
rm *.java
rm */*.java
rm lib/*.scm
cd d:\mt\release
rm askij.jar
jar cvf0 askij.jar com\*

echo Done!


