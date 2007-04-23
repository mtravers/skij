import java.applet.*;
import java.awt.*;

// Tripolar by Scott Snibbe. July 2002.


// Tripolar simulates a pendulum swinging above three magnets. The program draws
// the complete path that a pendulum would follow if it were released
// above the table exactly at the mouse point. This is a well-known
// chaotic system - very small changes to the starting position produce
// large changes to the path and which magnet on which it unltimately ends.
// The program drags the starting position slowly towards the actual
// mouse position, so that one can explore points between pixels, simulating
// a screen resolution hundreds of times the actual pixel resolution.

// The source code demonstrates the "meta-chaos" of the program itself.
// A set of key variables defines all the parameters of the simulation.
// Changing any of these parameters radically alters the artwork, in most
// cases making it non-functional - in some cases the program will hang, 
// in others the paths will explode, implode or oscillate.

// By its title, the program is also meant to suggest the connection between
// mental states and these chaotic phenomena - even small, simple physical
// systems are as unpredictable and sensitive to initial conditions as our
// own minds. Chaos and complexity reign at all scales.

public class Tripolar extends Applet implements Runnable
{
   // Controls whether we're updating animation
    Thread kicker_ = null;
   // Indication that animation thread has halted
    boolean timeToDie_;

   // Milliseconds between frame updates
   private int speed_;

   // Offscreen buffer for double-buffering
    Image offScrImage_;
   Graphics offScrGC_;

   int screenWidth_, screenHeight_;
   double centerX_, centerY_;
   double scale_;
   boolean down_ = false;

   Point mousePt_;
   double probeX_ = 1e10, probeY_ = 1e10;

   // These constants define the artwork - very slight changes to parameters
   // will make the program, implode, explode, or simply less interesting.
   // As a work exploring chaotic phenomena, these parameters show the "meta-chaos"
   // of the program itself - a nonlinear system extremely sensitive to 
   // initial conditions.
   // These choices also represent the hand of the individual artist in an 
   // algorithmic/technical work.

   double damping_ = 0.97;    // damping constant
   double gravity_ = 0.005;   // gravitational constant
   double magnetism_ = 0.1;
   double height_ = 0.1;      // vertical distance from magnets
   double mass_ = 1.0;        // mass of pendulum
   double dtSim_ = 0.01;      // time step

   double [] magnetX_, magnetY_;

   // Thread proc which updates animation
    public void run() {
       while (kicker_ != null) {
         updateAnimation();
         repaint();
         try {
            if (!timeToDie_) {
               Thread.sleep(speed_);
            } else {
               if (kicker_ != null) {
                  kicker_.stop();
                  kicker_ = null;
                  break;
               }
            }
         } catch (InterruptedException e) {
            break;
         }
      }
   }

    // Start the applet
    public void start() {
      requestFocus();

      if (kicker_ == null) {
         kicker_ = new Thread(this);
         kicker_.start();
      }
    }

    // Stop the applet.
    public void stop() {
      timeToDie_ = true;
    }

   public void init()
   {
      speed_ = 33;

      screenWidth_ =  size().width;
      screenHeight_ =  size().height;

      centerX_ = (double) screenWidth_ / 2.0;
      centerY_ = (double) screenHeight_ / 2.0;
      scale_ = Math.min(centerX_, centerY_);    // scale to normalize

      // Create offscreen buffer
      offScrImage_ = createImage(screenWidth_, screenHeight_);
      offScrGC_ = offScrImage_.getGraphics();

      // Background color for our applet
      setBackground(Color.white);
      setForeground(Color.black);

      mousePt_ = new Point();
      magnetX_ = new double [3];
      magnetY_ = new double [3];

      setMagnets(0.5);

      timeToDie_ = false;
   }

   // create three magnets at given radius from center
   void setMagnets(double r) {
      magnetX_[0] = r * Math.cos(Math.PI/2);
      magnetY_[0] = r * Math.sin(Math.PI/2);
      magnetX_[1] = r * Math.cos(Math.PI/2 + (2*Math.PI) / 3);
      magnetY_[1] = r * Math.sin(Math.PI/2 + (2*Math.PI) / 3);
      magnetX_[2] = r * Math.cos(Math.PI/2 - (2*Math.PI) / 3);
      magnetY_[2] = r * Math.sin(Math.PI/2 - (2*Math.PI) / 3);
   }

   // performs the simulation of the pendulum and draws the path
   void updatePaths(double x, double y, Graphics g) {
      double vX=0, vY=0;   // velocity
      double fX,fY;
      double r, over_rsq, over_rcube;
      double dx, dy;
      double filtVel = 1;
      double lastX, lastY;
      int iter = 0;

      // draw magnets 
      g.setColor(Color.red);
      for (int m = 0; m < 3; m++) {
	   magnetX_[m]
	       magnetY_[m]
      

      g.setColor(Color.black);
      while (filtVel > 0.1 && iter < 10000) {
         iter++;
         fX=0;
         fY=0; // zero forces

         // simulate gravitational pull towards center
         r = x*x + y*y;
         if (r < 0.00001)
            r= 0.00001;

         over_rsq = 1.0 / r;
         fX -= (x * gravity_) * over_rsq;
         fY -= (y * gravity_) * over_rsq;

         // simulate magnetic forces towards three magnets using 
         // Coulomb's 2nd law - attraction falls off with distance square
         for (int m = 0; m < 3; m++) {
            dx = magnetX_[m] - x;
            dy = magnetY_[m] - y;
            r = Math.sqrt(dx*dx + dy*dy + height_*height_);
            if (r < 0.00001)
               r = 0.00001;
            over_rcube = 1.0 / (r*r*r);

            fX += magnetism_ * dx * over_rcube;
            fY += magnetism_ * dy * over_rcube;
         }

         // friction proportional to velocity
         fX -= vX*damping_;
         fY -= vY*damping_;

         // Apply forces using Newton's Law: F=mA
         vX += dtSim_ * fX / mass_;
         vY += dtSim_ * fY / mass_;

         // compute filtered velocity, to determine when the pendulum stops
         filtVel = 0.99 * filtVel + 0.1 * Math.max(Math.abs(vX), Math.abs(vY));
         lastX = x;
         lastY = y;
         x += vX;
         y += vY;

         drawNormalizedLine(lastX, lastY, x, y, g);
      }
   }


   void drawNormalizedLine(double x1, double y1, double x2, double y2, Graphics g) {

      g.drawLine((int) Math.round(x1 * scale_ + centerX_),
               (int) Math.round(y1 * scale_ + centerY_),
               (int) Math.round(x2 * scale_ + centerX_),
               (int) Math.round(y2 * scale_ + centerY_));
   }

   // Override update so that it only calls paint.
   public void update(Graphics g) {
      paint(g);
   }

   void updateAnimation() {
      if (!down_) return;

      // interpolate from probe position to mouse position
      if (probeX_ == 1e10) {
         probeX_ = mousePt_.x;
         probeY_ = mousePt_.y;
      }

      double dx = mousePt_.x - probeX_;
      double dy = mousePt_.y - probeY_;
      double distSq = dx*dx + dy*dy;

      if (distSq > 1) { // exponentially proceed to pixel clicked on
         probeX_ += dx/2;
         probeY_ += dy/2;
      } else {       // logarithmically interpolate over last pixel
                     // This allows one to explore values between pixels
                     // by "pulling" the actual probe very slowly towards
                     // the mouse position.
         probeX_ += dx * 0.01;
         probeY_ += dy * 0.01;
      }
   }

   public void paint(Graphics g)
   {
      offScrGC_ = offScrImage_.getGraphics();

      // Draw all the graphics onto offscreen buffer
      offScrGC_.setColor(Color.white);
      offScrGC_.fillRect(0, 0, screenWidth_, screenHeight_);

      if (probeX_ != 1e10) {
         updatePaths((probeX_ - centerX_) / scale_,
                  (probeY_ - centerY_) / scale_, offScrGC_);
      }

      // Copy the offscreen buffer onscreen
      g.drawImage(offScrImage_, 0, 0, this);
   }

   public boolean mouseDown(Event evt, int x, int y) {
      down_ = true;
      mousePt_.setLocation(x, y);
      return true;
   }

   public boolean mouseUp(Event evt, int x, int y) {
      down_ = false;
      return true;
   }


   public boolean mouseDrag(Event evt, int x, int y) {
      if (down_) {
         mousePt_.setLocation(x, y);
      }
      return true;
   }

   public boolean mouseEnter(Event evt, int x, int y) {
      // Request that events are delivered to our applet
      requestFocus();

      return true;
   }
}








