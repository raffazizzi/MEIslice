# MEIslice

This is a Cocoon 2.2 block to slice MEI files by measure. It should produce a valid MEI 2013 file with the score definition closest to the beginning of the slice.

## Compiling the block and webapp

To compile the block so that it can be used in a webapp, run:

`$ mvn install`

Then step out of the directory to create a Cocoon 2.2. webapp:

`mvn archetype:generate -DarchetypeCatalog=http://cocoon.apache.org`

Pick option 3, then set the values for the Maven package (more info [here](http://cocoon.apache.org/2.2/1362_1_1.html)).

In the pom.xml setting file, load the block as dependency:

`<dependency>
	<groupId>org.mith</groupId>
	<artifactId>MEIslice</artifactId>
	<version>1.0.0</version>
</dependency>`

Then create the war package and you should be good to go:

`mvn package`

Deploy the war file to Tomcat or test it with jetty using

`mvn jetty:run`