#include <stdio.h>

typedef struct {
	double real;
	double img;
} complex;

double complex_abs(complex c)
{
    return c.real * c.real + c.img * c.img;
}

complex complex_mult(complex a, complex b)
{
    return (complex) {
		a.real * b.real - a.img * b.img,
		a.img * b.real + a.real * b.img
	};
}

complex complex_add(complex a, complex b)
{
    return (complex) {
		a.real + b.real,
		a.img + b.img
	};
}

char mandel(complex c)
{
    complex z = {0, 0};
    int h = 0;
    while (h < 20)
	{
        z = complex_add(complex_mult(z, z), c);
        if (complex_abs(z) > 2)
		{
            if (h % 2)
                return ' ';
            return '+';
		}
        h = h + 1;
	}
    return '%';
}

int main()
{
	double width=1000;
	double height=1000;

	double x=0;
	int c;
	while (x < width)
	{
//		line = "";
		double real = 3. * x / width - 1.5;
		double y = 0.;
		while (y < height)
		{
			double img = 3. * y / height - 1.5;
			c += mandel((complex){real, img});
//			line = line + mandel([real, img]);
			y = y + 1;
		}
		x = x + 1;
	}
	printf("%d\n", c);
//    print line;

//print "Complete!";
}