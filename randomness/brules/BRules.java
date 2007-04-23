package com.ibm.jikes.skij.brules; // if you change this, change the static initializer as well

import clpkrep.*;		// CLP
import com.ibm.jikes.skij.*;

/** 
 * Convert between CLP structures and XML files (both ways).
 * This class just provides glue for calling the Scheme 
 * procedures that do the work. It also provides a main 
 * method so that the package can be used standalone. This
 * main method provides a command-line interface for converting
 * between the CLP and XML representations.
 *
 * Requires: CLP, Skij, xml4j, the Scheme files referenced in the 
 * static initializer below.
 * 
 * @author Michael Travers
 */

public class BRules {

  static {
    try {
      String thisClass = "com.ibm.jikes.skij.brules.BRules";
      Scheme.initLibraries();
      Scheme.loadResource("brules.scm", thisClass);
    }
    catch (Throwable e) {
      System.out.println("Error initializing BRules: " + e.toString());
    }
  }
  
  /**
   * Write out a CLP structure as an XML file.
   */
  public static void CLP2XMLFile(CLP clp, String XMLoutFile) throws SchemeException {
    Scheme.procedure("clp->xmlfile").apply(Cons.list(clp, XMLoutFile));
  }

  /**
   * Read in an XML file and return a CLP structure.
   */
  public static CLP XMLFile2CLP(String XMLinFile) throws SchemeException {
    return (CLP)Scheme.procedure("xmlfile->clp").apply(Cons.list(XMLinFile));
  }

  public static void main(String[] args) {
    try {
      if (args[0].equals("-xmlin"))
	writeCLP(XMLFile2CLP(args[1]),args[2]);
      else if (args[0].equals("-xmlout"))
	CLP2XMLFile(readCLP(args[1]), args[2]);
      else {
	System.out.println("Args must be either:");
	System.out.println("  -xmlin foo.xml foo.clp");
	System.out.println("  -xmlout foo.clp foo.xml");
      }
    }
    catch (SchemeException e) {
      System.out.println("Error: " + e.toString());
    }
  }

  static void writeCLP(CLP clp, String filename) throws SchemeException {
    Scheme.procedure("write-clp-file").apply(Cons.list(clp, filename));
  }

  static CLP readCLP(String filename) throws SchemeException {
    return (CLP)Scheme.procedure("parse-clp-file").apply(Cons.list(filename));
  } 

  public String foo(ERule rule){
    return ((Literal)rule.getHead()).getPredicate().getSymName();
  }

}
