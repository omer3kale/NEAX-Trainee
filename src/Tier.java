package src;

public abstract class Tier implements Lebewesen{
	private int beine;
	String name;
	int augen;
	
	public static String getPlanet()
	{
		return "Erde";
	}
	
	public void setBeine(int beine)
	{
		this.pi = 5;
		if(beine <0)
		{
			this.beine = 0;
			return;
		}
		this.beine = beine;
	}
	
	public int getBeine()
	{
		verliereEinBein();
		return beine;
		
	}
	
	private void verliereEinBein()
	{
		if(beine < 1)
		{
			return;
		}
		this.beine--;
	}
	
	public String macheDichBemerkbar()
	{
		return "hey";
	}
	@Override
	public void atme() {
		System.out.println("schnauf");
	}
	
	public abstract void laufe();

}
