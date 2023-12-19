public static class Debug {
  public static boolean debug;

  public static boolean DO_SPECULAR = true;
  public static boolean DO_AMBIENT = true;
  public static boolean DO_SHADOWS = true;
  public static boolean DO_REFLECTION = true;
}

public class Ray {
  
  PVector origin;
  PVector direction;
  
  public Ray(PVector origin, PVector direction) {
    this.origin = origin;
    this.direction = direction;
  }
  
  //Given a t value, compute R(t) = o + t * d
  public PVector at(float t) {
    return PVector.add(this.origin, PVector.mult(this.direction, t));
  }
}

public class Material {
  PVector difColor;
  PVector ambColor;
  PVector specColor;
  float specPow;
  float kRefl;
  
  public Material(PVector difColor, PVector ambColor, PVector specColor, float specPow, float kRefl) {
    this.difColor = difColor;
    this.ambColor = ambColor;
    this.specColor = specColor;
    this.specPow = specPow;
    this.kRefl = kRefl;
  }
}

public class Light {
  PVector pos;
  PVector col;
  
  public Light(PVector pos, PVector col) {
    this.pos = pos;
    this.col = col;
  } 
}

/* Upon a ray hitting the shape, store the calculated root (t-value),
 * the actual intersection point for the ray and the shape, the normal vector,
 * and the shape that was hit (for shading purposes)
 */
public class Hit {
  PVector norm;
  PVector interPoint;
  float t;
  Shape hitShape;
  Ray ray;
  
  public Hit(float t, PVector interPoint, PVector norm, Shape hitShape, Ray ray) {
    this.t = t;
    this.interPoint = interPoint;
    this.norm = norm;
    this.hitShape = hitShape;
    this.ray = ray;
  }
}

//Parent class for Sphere and Triangle
public abstract class Shape {
  Material mat;
  
  public Shape(Material mat) {
    this.mat = mat;
  }
  
  public abstract Hit intersectRay(Ray ray);
}

public class Sphere extends Shape {
  float radius;
  PVector center;
  
  public Sphere(float radius, PVector center, Material mat) {
    super(mat);
    this.radius = radius;
    this.center = center;
  }
  
  public Hit intersectRay(Ray ray) {
    // Check if the ray is intersecting with the given sphere. Returns null if no intersection.
    
    //Get vector from the center to the origin
    PVector origRelCenter = PVector.sub(ray.origin, this.center);
    
    // First, you need to calculate quadratic coefficients
    float a = ray.direction.x * ray.direction.x + 
              ray.direction.y * ray.direction.y + 
              ray.direction.z * ray.direction.z;
    float b = 2 * (ray.direction.x * origRelCenter.x + 
                   ray.direction.y * origRelCenter.y + 
                   ray.direction.z * origRelCenter.z);
    float c = origRelCenter.x * origRelCenter.x + 
              origRelCenter.y * origRelCenter.y + 
              origRelCenter.z * origRelCenter.z -
              radius * radius;
    
    if (Debug.debug)
    {
      println("testing intersection with the sphere whose diffuse color is: " + mat.difColor);
      println(String.format("a, b, c coefficients of quadratic: %f, %f, %f", a, b, c));
    }
    
    // You need to compute discriminant and handles the cases properly. Returns null if there is no colission.
    float discriminant = b * b - (4 * a * c);
    if (discriminant <= 0 || a == 0)
    {
      if (Debug.debug)
      {
        println("this quadratic equation has no solutions! returning null");
        println();
      }
      return null;
    }
    

    float t = (-b - sqrt(discriminant)) / (2 * a);

    if (t < 0)
    {
      return null;
    }
    
    PVector intersectionPoint = ray.at(t); 
    PVector sphereNorm = PVector.sub(intersectionPoint, center); 
    sphereNorm.normalize();
    
    if (Debug.debug)
    {
      println("found a hit!");
      println("time: " + t);
      println("intersection point: " + intersectionPoint);
      println("norm: " + sphereNorm);
      println();
    }
    // ===== (TODO) Stage 3b ends =======
    
    return new Hit(t, intersectionPoint, sphereNorm, this, ray);
  }
  
}

public class Triangle extends Shape {
  PVector v1;
  PVector v2;
  PVector v3;
  PVector normal;


  public Triangle(PVector v1, PVector v2, PVector v3, Material mat) {
    super(mat);
    this.v1 = v1;
    this.v2 = v2;
    this.v3 = v3;
    this.normal = PVector.sub(v2, v1).cross(PVector.sub(v3, v1)).normalize();
    // if (Debug.debug)
    {
      println(String.format(
        "making a triangle! v2-v1: %s, v3-v1: %s, normal: %s, normalized: %s",
        PVector.sub(v2, v1),
        PVector.sub(v3, v1),
        PVector.sub(v2, v1).cross(PVector.sub(v3, v1)),
        PVector.sub(v2, v1).cross(PVector.sub(v3, v1)).normalize()
      ));
    }
  }
  
  public Hit intersectRay(Ray ray) 
  {
    
    if (Debug.debug)
    {
      println(String.format(
        "testing intersection with the triangle whose points are: %s, %s, %s", v1, v2, v3
      ));
      println();
    }

    // u = v1 - rayorigin
    // t = - (N * u)/(N * raydir)
    PVector u = PVector.sub(this.v1, ray.origin);
    
    if (PVector.dot(this.normal, ray.direction) == 0)
    {
      return null;
    }
    
    float t = PVector.dot(this.normal, u) / PVector.dot(this.normal, ray.direction);

    if (t < 0)
    {
      return null;
    }
    
    PVector intersection = PVector.add(ray.origin, PVector.mult(ray.direction, t)); 
    
   
    PVector p = intersection;
    //PVector ab = PVector.sub(this.v2, this.v1);
    //PVector ap = PVector.sub(p, this.v1);
    //PVector cross = ab.cross(ap);
    //float dot = PVector.dot(cross, this.normal);
    float x = PVector.dot((PVector.sub(p, this.v1)).cross(PVector.sub(this.v2, this.v1)) , this.normal);
    float y = PVector.dot((PVector.sub(p, this.v2)).cross(PVector.sub(this.v3, this.v2)) , this.normal);
    float z = PVector.dot((PVector.sub(p, this.v3)).cross(PVector.sub(this.v1, this.v3)) , this.normal);

    

    PVector bary = new PVector(x,y,z);    
    
    
    if (Debug.debug)
    {
      println("intersection point: " + intersection);
      println("Bary: " + bary);
      println();
    }

    boolean hit = false;
    if( (x>0 == y>0) && (y>0 == z>0)) {
      hit = true;
    }
      
    if (hit)
    {
      PVector hitNormal = PVector.dot(this.normal, ray.direction) < 0 ? this.normal : PVector.mult(this.normal, -1);
    
      if (Debug.debug)
      {
        println("found a triangle hit!");
        println("time: " + t);
        println("norm: " + hitNormal);
        println();
      }

      return new Hit(t, intersection, hitNormal, this, ray);
    }
    else
    {
      return null;
    }
  }
  
}
