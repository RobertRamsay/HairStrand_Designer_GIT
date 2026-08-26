/// @description Insert description here
// You can write your code in this editor
//img=9
	{
	seedValstring=seedVal
	seedValstring=get_integer("Enter a seed value",random_get_seed())
	
    }
	
	if seedValstring {random_set_seed(seedValstring) ;seedVal=seedValstring
		if setSelectedID==-1
		for (b=0;b<maxSets;b++)
			{
			randomSeedVal[b]=seedVal
			}
		else
		{
			randomSeedVal[setSelectedID]=seedVal
		}
		seedUpdate=1

		}
	
	

