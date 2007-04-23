package com.ibm.jikes.skij.misc;
import com.ibm.jikes.skij.*;
import java.awt.*;

import javax.swing.JTable;
import javax.swing.table.DefaultTableCellRenderer;

import com.sun.java.swing.*;

// total kludge to insert style changes into table cells! wow!

// 1.1.5 -- DefaultCellRenderer
// 1.1.6 -- table.DefaultTableCellRenderer
// 1.2 -- java.awt.swing.table.DefaultTableCellRenderer
// what next?
public class SkijCellRenderer extends DefaultTableCellRenderer {
  
  Procedure proc;

  public SkijCellRenderer(Procedure p) {
    super();
    proc = p;
  }
       
  
  public Component getTableCellRendererComponent(JTable table,
						 Object value,
						 boolean isSelected,
						 boolean hasFocus,
						 int row,
						 int column) {
    Component result = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
    try {
      proc.apply(Environment.top, Cons.list(table, value, new Integer(row), new Integer(column), this)); } // this was getComponent()
    catch (SchemeException e) {
      System.out.println("Error in " + this);
      e.printBacktrace();
      throw new Error(e.toString()); 
    }
    return result;
  }
}
