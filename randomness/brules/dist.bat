echo make BRules distribution

cd d:\java\misc\com\ibm\jikes\skij\brules
clean
cd d:\java\misc
rm d:\mt\release\brules.zip
jar cvfM d:\mt\release\brules.zip com\ibm\jikes\skij\brules\*
