def complex_abs(c):
    return c[0] * c[0] + c[1] * c[1]

def complex_mult(a, b):
    return [a[0] * b[0] - a[1] * b[1], a[1] * b[0] + a[0] * b[1]];

def complex_add(a, b):
    return [a[0] + b[0], a[1] + b[1]]

def mandel(c):
    z = [0, 0]
    h = 0
    while (h < 20):
        z = complex_add(complex_mult(z, z), c)
        if (complex_abs(z) > 2):
            if h % 2:
                return " ";
            return "+";
        h = h + 1;
    
    return "%"

width=1000
height=100

x=0
while (x < width):
    line = "";
    real = 3. * x / width - 1.5;
    y = 0.;
    while (y < height):
        img = 3. * y / height - 1.5;
        mandel([real, img]);
        y = y + 1;
    x = x + 1;
#    print line;

print "Complete!";
