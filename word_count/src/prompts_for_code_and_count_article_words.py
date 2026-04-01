tag_instructions_prompt_intro = """

You are going to identify content in newspaper articles by marking the start and end of content blocks that cover specific topics. The newspaper articles are all about disruptive environmental protest. Disruptive protest is defined as follows:

Disruptive protest is protest that appears to be aimed at disrupting the functioning of some other activity generally regarded as legitimate (whether that is fossil fuel operations, road transport, sport, government operations, cultural displays, etcetera) as a means to draw attention to a cause or as a means to prevent the activity. Disruption is not dependent on the actual scale of disturbance of economic or social life. For example, a registered march in a city can cause great inconvenience, but because the disruption is a side-effect of the marchers’ primary intention to amplify their communications by gathering in numbers, we do not regard this as disruptive protest. Protest conducted by groups that often disrupt is not inherently disruptive. Such groups sometimes protest in ways that superficially resemble their disruptive protests without intending to disrupt on that occasion.

These are the five types of content to be marked. Note, actions that are reported as being planned rather than as having happened count in the same way as if they had happened.

DISRUPTION effects (direct or knock-on) of the disruptive protest. If article content superficially seems like it describes a disruption effect, then it does - there are no special reasons why some descriptions of disruption effects don't count. Knock-on effects such as court proceedings do count as disruption effects. Start tag: #DS. End tag: #DE.
PROTESTER MESSAGING - the messages protesters are trying to convey, for example quotes (from a person or on a banner) or reported summaries of things protesters said. Take care to include messaging only from protesters or their allies, not messaging from critics of protesters. Start tag: #MS. End tag: #ME.
POSITIVE COMMENTS - approval of the protest, protesters, or the protest's effects (and only those), expressed by anyone except the protesters themselves. This might be expressed by any quoted individual in any capacity in any way (e.g., politician, commentator, but not the protesters), or reported in general terms (e.g., “passers-by shouted approvingly”), or expressed by the author of the article. Start tag: #PS. End tag: #PE.
NEGATIVE COMMENTS - criticism of the protest, protesters, or the protest's effects (and only those), expressed by any quoted individual in any capacity in any way (e.g. a judge when sentencing, police, politician, commentator, other environmentalist, member of the public), reported in general terms (e.g., “passers-by shouted disapprovingly”), or expressed by the author of the article. Start tag: #NS. End tag: #NE.

You will mark content blocks by inserting start and end tags into the article text. You will reproduce the article content exactly as it is provided, but you will insert tags that mark the start and end of blocks of content. All content that is of a type defined above must be marked as being inside a content block of the correct type.  Different types of content block can potentially overlap, because content could fulfil criteria to be included in more than one category. Here is an example created to illustrate this: "Extinction Rebellion protesters were on the streets of London today. #DS They blocked a main road using #MS a banner saying 'End Fossil Fuels Now'. #ME #DE #NS Minister Priti Patel said 'This government will never give in to the eco-yobs.' #NE"

The articles come in sections: ID, title, subtitle, and main content (marked just as content). Do not code the ID but code the other three sections. The Subtitle may be missing. Do not start a content block in one section and carry it over into the next section. End the block and if necessary start it again in the next section. 

There are some tags already in the article content, relating to pictures from the original article. #PH indicates that a picture was here. #PH will normally be followed by #CS and #CE which indicate the start and end of text that is the caption and alt text for that picture. When you are coding, use the caption and alt text to determine what is in the picture, and include it in blocks if necessary, by making sure the relevant #PH tag is inside the block. For example, a picture indicated as containing banners with messages should be inside a messaging content block. As another example, a picture showing a road block should be inside a disruption effects block.

Below are four articles that have already been coded in this manner. Note, there are also comments on the article that help explain the justification for coding choices made. The places in the material that the comments apply to are marked [COMMENTX] where X is a number, and the same [COMMENTX] identifiers appear at the end where the comments themselves are given.


ID: BBC_2020-09-05_Extinction-Rebellion-protesters
Source: BBC
Title: #DS Extinction Rebellion protesters block newspaper printing presses #DE[COMMENT1]
Content: #DS[COMMENT2] #PH #CS Protesters gathered outside the sites - including Broxbourne in Hertfordshire - owned by Rupert Murdoch's News Corporation (Alt: Protesters climbing on a vehicle at a blockade near the Broxbourne printing press)#CE [COMMENT3]
Extinction Rebellion (XR) activists have delayed the distribution of several national newspapers after blocking access to three printing presses owned by Rupert Murdoch. Protesters targeted Newsprinters presses at Broxbourne in Hertfordshire, Knowsley in Merseyside, and near Motherwell, North Lanarkshire. #DE[COMMENT4] #NS Prime Minister Boris Johnson said the action was "unacceptable" #NE[COMMENT5].



#DS [COMMENT6] Eighty people have been arrested. The presses print the Rupert Murdoch-owned News Corp titles including the Sun, the Times, the Sun on Sunday, the Sunday Times, and the Scottish Sun. They also print the Daily Telegraph and Sunday Telegraph, the Daily Mail and Mail on Sunday, and the London Evening Standard.[COMMENT7]



XR used vehicles to block roads to the printing plants, while individual protesters chained themselves to structures. [COMMENT8]#DE[COMMENT9] #MS Vans were covered with banners with messages including "Free the truth" and "Refugees are welcome here".



Demonstrators have accused the papers of failing to report on climate change. #ME[COMMENT10] #NS Boris Johnson said, "A free press is vital in holding the government and other powerful institutions to account on issues critical for the future of our country, including the fight against climate change. It is completely unacceptable to seek to limit the public's access to news in this way." #NE
#DS[COMMENT11] #PH #CS XR used vehicles along with individual protesters chaining themselves to structures to block roads to the presses (Alt: Protesters climbing and chaining themselves to structures outside a printing press)#CE 


Hertfordshire Police said officers were called to Great Eastern Road[COMMENT12] near the Broxbourne plant at about 22:00 BST, where they found about 100 protesters who had "secured themselves to structures and one another". By 06:00 delivery lorries had still been unable to leave the site to distribute papers. #DE[COMMENT13]



#MS XR has accused the newspapers and their owners of "failure to report on the climate and ecological emergency" and "polluting national debate" on dozens of social issues. The group is calling on the government to do more to act on climate change. #ME[COMMENT14]


ID: BBC_2020-09-20_GM-crops_-The
Source: BBC
Title: GM crops: [COMMENT15]#DS The Greenpeace activists who risked jail to destroy a field of maize #DE
Content: #DS [COMMENT16]#PH#CS Greenpeace protesters destroy a field of GM crops at Lyng, Norfolk on 26 July 1999 (Alt: Greenpeace activists in white overalls destroying a field of maize)#CE 
In a landmark environmental protest, 28 Greenpeace activists destroyed a field of genetically-modified (GM) maize on a farm in Norfolk in July 1999. #DE[COMMENT17] The group, which included a vicar and a beauty consultant, was led by Greenpeace executive director Lord Peter Melchett, a former government minister and Norfolk farmer.



#DS[COMMENT18] At 05:00 BST on 26 July, the protesters stormed the six-acre field of modified fodder maize, trampling and pulling at the 7ft plants. They used a machine with whirling 4ft blades to destroy a large section of the crop, planning to bag it up and deliver it to Norfolk-based GM contractors AgrEvo. #DE



#MS The activists opposed such trials, claiming they would cause genetic pollution of the environment. Michael Uwins, Greenpeace's East of England co-ordinator, stated, "We totally believed in what we were doing. We were not anti-science or GM as such; it was about open-air field trials. It was irresponsible and had to be stopped." #ME[COMMENT19]
#PH#CS Now 74, Michael Uwins describes himself as an "armchair activist" (Alt: An elderly smiling man standing on a beach) #CE 


#NS The protesters were confronted by the "furious" landowner William Brigham and family members, who were "ramming and chasing the protesters around the field." #NE [COMMENT20]#DS Police soon arrived, and the activists were arrested and charged with criminal damage and theft. #DE



#MS In court, the protesters argued they had lawful excuse for their actions, aiming to prevent neighbouring land from being unlawfully invaded by genetically-modified pollen. #ME After two trials, all defendants were acquitted on 20 September 2000.



The verdict was seen as a triumph by environmental activists but #NS described as "perverse" by the National Farmers' Union, which claimed it gave "the green light to wanton vandalism and trespass." #NE[COMMENT21]



This key moment in environmental protest brought the issue of GM crops to the attention of politicians, regulators, and the media, resulting in a more cautious approach to GMO release in the UK.
#DS #PH#CS Lord Peter Melchett was arrested at the scene (Alt: An environmental protester in a field being arrested by a police officer) #CE #DE


ID: BBC_2020-09-01_Arrests-as-Extinction
Source: BBC
Title: #DS Arrests as Extinction Rebellion protests begin across England #DE
Content: #DS #PH#CS Extinction Rebellion said it planned to "peacefully disrupt" Parliament with 10 days of demonstrations (Alt: An activist from the climate protest group Extinction Rebellion is carried away by police officers) #CE 
At least 90 people have been arrested at climate change protests causing disruption across England. Extinction Rebellion organised action in London to #MS urge the government to prepare for a "climate crisis" #ME. Campaigners were arrested after they sat in the middle of the road next to Parliament Square to stop traffic. #DE



#DS[COMMENT22] #MS[COMMENT23] Extinction Rebellion said it planned to "peacefully disrupt the UK Parliament in London" with 10 days of demonstrations until MPs backed the Climate and Ecological Emergency Bill. #ME Other planned events in the capital include a #MS "carnival of corruption", which is due to take place outside the Treasury, and a "walk of shame" near the Bank of England. #ME #DE



#MS Protester Karen Wildin, a 56-year-old tutor from Leicester, said: "I'm here today because I have serious concerns about the future of the planet - we need to put this above anything else. Never mind Covid, never mind A-levels, this is the biggest crisis facing us and we need to raise the message as loudly as possible." #ME
#DS #PH#CS The Met said the protests could result in "serious disruption" to businesses and commuters (Alt: An activist lying in the street is spoken to by police officers) #CE #DE


#MS Sarah Lunnon, a member of Extinction Rebellion, said: "The failure to act on this issue will have a catastrophic impact on the future of us and the generations to come. We want to occupy Parliament Square to make our voices heard. Of course we're in the middle of a pandemic but we're balancing the risk, this is the biggest issue facing us." #ME


#PS Professor Peter Franklin, who studies climate change at a London University, said: "Although not everyone welcomes the protests, I see them as necessary to help bring about more action on climate change." #PE


The Metropolitan Police said Tuesday's gathering could only take place off the main roads at Parliament Square Gardens between 08:00 BST and 19:00. Boats, vehicles, trailers or other structures were banned from the procession. The same rules apply for Wednesday's demonstrations.[COMMENT24]



#DS #NS Met Commander Jane Connors said: "The reason we have implemented these conditions is that we know these protests may result in serious disruption to local businesses, commuters and our communities and residents, which I will not tolerate." #NE



Last year, more than 1,700 arrests were made during Extinction Rebellion's 10-day Autumn Uprising.
#PH#CS Protesters gathered in Westminster to urge the government to prepare for a "climate crisis" (Alt: A line of police surrounds a crowd of protesters) #CE #DE

ID: sun_example
Source: Sun
Title: #DS #NS Eco-zealots glue themselves #NE to priceless painting #DE
Subtitle: #DS Gallery chaos as protesters strike again #DE
Content: #DS #NS Eco-zealots brought a top London gallery to a standstill #NE yesterday after supergluing themselves to a masterpiece worth millions.
#NS The barmy activists caused mayhem #NE at the National Gallery when they attached their hands to the frame of a Van Gogh painting during the morning rush.
#NS Furious visitors were left fuming #NE as security guards scrambled to deal with the protesters, #MS who were chanting slogans about climate change. #ME #DE

[COMMENT1]Note, the entire title is clearly about disruption, so it’s a disruption content block. The block ends even though the first content (which happens to be a picture) is also about disruption, because we don’t continue blocks across sections (title, subtitle (which is missing here), and main text (which starts “Content:”)).
[COMMENT2]Note – this #DS (disruption start) is before the #PH (picture here). This means the picture is included in the block of disruption content - appropriate because the caption and the alt text indicate that the picture illustrates disruption.
[COMMENT3]Note – no #DE yet, so we are still in a disruption content block, because the article text following the picture describes disruption. 
[COMMENT4]Now I ended the disruption block because while everything up to here was detailing disruption, the Johnson quote is commenting on the disruption rather than describing it.
[COMMENT5]This is clearly negative criticism of the actions.
[COMMENT6]How many are arrested gives information about the level of disruption, so we start a disruption block again.
[COMMENT7]Still in a disruption block because this is clearly information about which newspapers may have been affected by the disruption.
[COMMENT8]Still obviously about the disruption so still inside the disruption content block.
[COMMENT9]I ended the disruption block here because although the vans were used to cause disruption, the information about what they were “covered with” doesn’t tell us anything more about the disruption itself.
[COMMENT10]Note the messaging block ends here because the sentence following the banners is also reporting on the protesters’ reasons for the protest, which is definitely also part of their messaging. But again, the Johnson quote is neither providing details of the disruption nor the protesters messaging – but it is a negative criticism block.
[COMMENT11]Starting a disruption block here because the picture and the caption are about the disruption, in the same way that the previous picture was.
[COMMENT12]I considered not including this in the disruption block because information about what police do is not necessarily about the details of disruption, but I left it in because the police came because of the disruption and because police being required to attend to deal with disruption is itself part of the disruption.
[COMMENT13]The next bit is only about protesters messaging so the disruption block ends here.
[COMMENT14]The entire paragraph was clearly about the protesters’ messaging.
[COMMENT15]Note, I didn’t include this first bit of the title in the disruption content block as this part of it doesn’t tell us anything about the disruption.
[COMMENT16]I justify the inclusion of the picture in the same way as in the previous article.
[COMMENT17]I ended the disruption block here because although everything till now (including picture and caption) has been detailing the disruptive acts, the details of the occupations of the protesters doesn’t tell us about the disruption they carried out.
[COMMENT18]I’m no longer commenting on choices that are by now (I hope) obvious.
[COMMENT19]Note that this is a messaging block because it is messages protesters are trying to convey. Although it expresses approval of the action, it is not coded as an approval of the protest block, because that needs to be expressed by anyone except the protesters themselves
[COMMENT20]This block represented a rather extreme example of negative comment on the protesters, as the expression of "furious" sentiment involved the protesters being rammed and chased.  
[COMMENT21]Note the careful positioning of the #NS tag so that the “verdict [being] seen as a triumph by environmental activists” is not included in a negative criticism block. The “triumph” phrase is not including in an approval block because it is an expression from activists themselves.
[COMMENT22]Note that actions reported as planned count in the same way as is they have happened.
[COMMENT23]Note, this messaging block begins while in a disruption block, because the threat to disrupt unless demands are met is both part of messaging and part of a description of disruption
[COMMENT24]I didn’t put this in a disruption block because it’s not clear whether these conditions relate to anything that was actually planned or happened.


End of three example articles. Here is the article for you to tag:
"""

test_article = """
ID: BBC_2020-09-04_Extinction-Rebellion_-More
Source: BBC
Title: Extinction Rebellion: More than 300 arrested at London climate protests
Content: #PH  #CS Extinction Rebellion has planned 10 days of action and wants the government to declare a climate and ecological emergency #CE 
More than 300 people have been arrested during the third day of climate change protests in central London.

Extinction Rebellion, which has planned 10 days of action, and other groups gathered at city landmarks on Thursday.

Of those arrested, Scotland Yard said, more than 200 were linked to a demonstration on Lambeth Bridge near the Houses of Parliament.

Extinction Rebellion said police had refused to let peaceful protesters leave the bridge.

The bridge was blocked when some protesters "locked on" and attached themselves to it, police said.

It has since reopened to traffic.

Elsewhere, protesters from the group Animal Rebellion glued themselves to the top and the inside of slaughterhouse truck painted pink.
#PH  #CS Getty Images Protesters glued to the top of a slaughterhouse van painted pink #CE 
The vehicle was cordoned off after being parked sideways across Victoria Street.

Protesters also glued themselves to the ground around Parliament, while others staged sit-ins around the perimeter of the parliamentary estate.

Extinction Rebellion said it wants the government to declare a climate and ecological emergency, reduce greenhouse gas emissions to net zero by 2025 and establish a "citizens' assembly on climate and ecological justice".

More protests are planned on Friday and the Met has imposed restrictions on one event due to be held in Parliament Square.

It has ordered campaigners to stay off main roads and to leave the area by 19:00 BST.
"""

tag_instructions_prompt_end = """
End of article for tagging. Now respond with the entire article in its original format exactly as I provided it, except with the addition of tags, as appropriate. 
"""

have_another_go_no_error_prompt = """
Occasionally mistakes are made. The formatting of your tagging is correct - good - but sometimes the wrong content is tagged. Please check your previous output for compliance to the rules of this tagging task. If you have made any mistakes, please produce new output that corrects the mistakes. If you have not made any mistakes, please repeat the previous output. Note that being given an opportunity to make corrections does not imply you have made mistakes.
"""

have_another_go_after_error_prompt = """
Occasionally mistakes are made. There is indeed a format error in your tagging. It's also possible the wrong content is tagged, but this has not been checked and it may be correct. Please check your previous output for compliance to the rules of this tagging task and produce new output that corrects the mistakes. The error that your tagging has raised is:
"""