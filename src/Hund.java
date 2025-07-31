package src;

public class Hund extends Tier {
	String rasse = "dalmatiner";
	
	public String gibRassezurück()
	{
		return rasse;
	}
	
	public String macheDichBemerkbar()
	{
		return "wau";
	}
	
	public void atme()
	{
		System.out.println("hechel");
		
	}
	
	@Override
	public void laufe()
	{
		System.out.println("hüpf");
	}

}
