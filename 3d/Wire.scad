// Magic Wire Jumper for Team Thermocline

// ---- params (mm)
wire_d = 1.628;   // 14 AWG bare copper dia
wire_r_core = wire_d/2;   // copper core radius
wire_d_insul = 2.5; // Approx 14 AWG wire dia
strip_down = 5; // Wire below the board
wire_r = wire_d_insul/2;

$fn = 32;

x_end = 12.5;
mid   = [0, 10, 8];

dz_stub = 6;      // end tangent strength (+Z)
dx_tan  = 8;      // mid tangent strength (+X)
N = 80;           // segments

// ---- tiny vector helpers
function vadd(a,b) = [a[0]+b[0], a[1]+b[1], a[2]+b[2]];
function vsub(a,b) = [a[0]-b[0], a[1]-b[1], a[2]-b[2]];
function vmul(a,s) = [a[0]*s, a[1]*s, a[2]*s];

// cubic bezier point
function bez3(p0,p1,p2,p3,t) =
    vadd(
      vadd(vmul(p0, pow(1-t,3)),
           vmul(p1, 3*pow(1-t,2)*t)),
      vadd(vmul(p2, 3*(1-t)*pow(t,2)),
           vmul(p3, pow(t,3)))
    );

// endpoints
p0 = [-x_end, 0, 0];
pM = mid;
p1 = [ x_end, 0, 0];

// segment A controls (p0 -> pM)
a0 = p0;
a1 = vadd(p0, [0, 0, dz_stub]);
a3 = pM;
a2 = vsub(pM, [dx_tan, 0, 0]);

// segment B controls (pM -> p1)
b0 = pM;
b1 = vadd(pM, [dx_tan, 0, 0]);
b3 = p1;
b2 = vadd(p1, [0, 0, dz_stub]);

// sample piecewise curve into points
function path_pt(i) =
    let(t = i / N)
    (t <= 0.5)
      ? bez3(a0,a1,a2,a3, t*2)
      : bez3(b0,b1,b2,b3, (t-0.5)*2);

// capsule segment between two points
module seg(p, q, r) {
  hull() {
    translate(p) sphere(r=r);
    translate(q) sphere(r=r);
  }
}


union() {
  // Chop the insulated wire along the XY plane (keep z >= 0)
  intersection() {
    for (i=[0:N-1])
      seg(path_pt(i), path_pt(i+1), wire_r);

    translate([-100, -100, 0])
      cube([200, 200, 200]);
  }

  // Add "stripped" copper ends below the plane at both endpoints
  translate(p0) translate([0,0,-strip_down])
    cylinder(r=wire_r_core, h=strip_down);

  translate(p1) translate([0,0,-strip_down])
    cylinder(r=wire_r_core, h=strip_down);
}
