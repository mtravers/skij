using System;
using System.Windows.Forms;
using com.ibm.jikes.skij;

namespace MDL {

public class SkijButton : Button {

  String script;

  public String Script {
    get { 
      return script;
    }
    set {
      script = value;
    }
  }

  public SkijButton() {
    this.Click += new EventHandler(clickScriptButton);
  }


  void clickScriptButton (object sender, System.EventArgs e) {
    try {
      Scheme.evalString("(load \"d:/mt/projects/skij/SkijSharp/xbrowser.scm\")"); // should only be done once of course
      Scheme.evalString("(def-all-widgets)");
      Scheme.evalString(Script);
    }
    catch (Exception ee) {
      Console.WriteLine("Error in skij script: " + ee);
    }
  }

}
}
 
