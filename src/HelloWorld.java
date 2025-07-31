package src;

public class HelloWorld {
	
	public static void main(String[] args) {
		Tier.getPlanet();
		Tier t = new Hund();
		Hund h = (Hund)t;
		t.atme();
		System.out.println(t.atme());
		Lebewesen l = new Fish();
		l.atme();
		
		Lebewesen[] ls = new Lebewesen [10];
		for(int i = 0; i < 10; i++)
		{
			ls[i] = new Fish();
			ls[i].atme();
		}
		
		ls[5] = new Hund();
		ls[4] = new Tier();
		
		for(int i = 0; i < 10; i++)
		{
			ls[i].atme();
		}
	}

}
