package com.ibm.jikes.skij.misc;

import java.applet.*;
import java.awt.Image;
import java.awt.Graphics;
import java.awt.image.ColorModel;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.Enumeration;
import java.util.Iterator;

import sun.applet.AppletResourceLoader;

/**
 * Support class for running applets under Skij. 
 */
public class SkijAppletContext implements AppletContext {

	/* obs?
  public AudioClip getAudioClip(URL uRL) {
    return AppletResourceLoader.getAudioClip(uRL);
  }
  */

  public Image getImage(URL uRL) {
    System.out.println("getImage " + uRL);
    return AppletResourceLoader.getImage(uRL);
  }


  public Applet getApplet(String name) {
    return null;
  }

  public Enumeration getApplets() {
    return null;
  }

  public void showDocument(URL url) {
  }
  public void showDocument(URL url, String target) {
  }

  public void showStatus(String status) {
    System.out.println(status);
  }


public AudioClip getAudioClip(URL url) {
	// TODO Auto-generated method stub
	return null;
}


public InputStream getStream(String key) {
	// TODO Auto-generated method stub
	return null;
}


public Iterator<String> getStreamKeys() {
	// TODO Auto-generated method stub
	return null;
}


public void setStream(String key, InputStream stream) throws IOException {
	// TODO Auto-generated method stub
	
}
}

