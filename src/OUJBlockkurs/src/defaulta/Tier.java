package defaulta;

public abstract class Tier implements Lebewesen {
	private int beine;
	
	public static String getPlanet()
	{
		return "Erde";
	}
	
	public void setBeine(int beine)
	{
		if(beine <0)
		{
			this.beine = 0;
			return;
		}
		this.beine = beine;
	}
	public int getBeine()
	{
		return beine;
	}
	
	public String macheDichBemerkbar()
	{
		return "hey";
	}
	public abstract void laufe();
	
}
