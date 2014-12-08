-- http://community.usvsth3m.com/generator/clickbait-headline-generator

local utils = require("irc.utils")

local p = {
	{
		{"3", "7", "11", "15", "19", "23", "27", "31", "35", "39", "43", "47", "51", "55", "59", "63", "67", "71", "75"},
		{"Things", "Lies", "Secrets", "Tips", "Pick-Up Lines", "Feelings", "Secrets", "Sex Tips", "Diet Tips", "Facts", "Photos", "Animated GIFS", "Vines", "Words", "Maps", "Diagrams", "Sassy Comebacks", "Hacks", "Life Hacks"},
		{"All", "Some", "That", "Only"},
		{"Perfectionists", "Big-Boobed Women", "Men With Small Dicks", "Tall Women", "Short Women", "Tall Men", "Short Men", "English Men", "American Men", "German Men", "English Women", "French Women", "Chinese Women", "Kitten Owners", "Londoners", "Northerners", "Forgetful People", "90s Kids", "Single People"},
		{"Believe", "Love", "Can't Live Without", "Will Understand", "Will Know All Too Well", "Should Have Thought About Harder", "Have Been Waiting Their Whole Life For", "Share", "Adore", "Cry About", "Should Never Be Ashamed Of", "Will Relate To", "Won't Believe Actually Exist", "Won't Tell You", "Don't Need To Answer", "Know Are Actually Lies", "Will Remember", "Write Tweets About", "Post On Facebook"}
	},
	{
		{"3", "5", "7", "9", "11", "13", "15", "17", "19", "21", "23", "25", "27", "29", "31", "33", "35"},
		{"Bars Of Soap", "Beards", "Beds", "Bees", "Bits Of Acne", "Bits Of Folded A4 Paper", "Bits Of Wool", "Boxes", "Breakfasts", "Buildings", "Buttons", "Cakes", "Candles", "Car Parks", "CDs", "Chairs", "Chickens", "Churches", "Clocks", "Corporate Logos", "Couches", "Cows", "Crisp Packets", "Crows", "Cups", "Dead Fish", "Desks", "Digital Watches", "Doorknobs", "Elephants", "Fingernails", "Flowers", "Geometric Shapes", "Goats", "Goldfish", "Hairbrushes", "Hats", "Houses", "Html Tags", "Kittens", "Lamps", "Lampshades", "Light Switches", "Minecraft Mods", "Moustaches", "Pencils", "Periodic Elements", "Photographs Of Gas", "Picture Frames", "Pigs", "Remote Controls", "Sheep", "Shoelaces", "Slices Of Bacon", "Sofas", "Spiders", "USB Drives", "Tables", "Telephones", "Toothbrushes", "Tractors", "TVs", "Typewriters", "Wasps", "Windows", "Wombles", "Xylophones", "Leather Gloves", "Mole Rats", "Owls", "Versions of Microsoft Windows", "Bits of ASCII Art", "Teletext pages"},
		{"That Look Like"},
		{"Adrian Chiles", "Alan Turing", "Aleister Crowley", "Amanda Holden", "Amy Winehouse", "Andy Murray", "Aneurin Bevan", "Anne Robinson", "Ant and Dec", "Barack Obama", "Beyonce", "Bob Dylan", "Bob Geldof", "Bobby Moore", "Bono", "Boris Johnson", "Boudicca", "Boy George", "Britney Spears", "Catherine Zeta-Jones", "Celine Dion", "Charles Babbage", "Charles Dickens", "Cher", "Cheryl Cole", "Chris Evans", "Chris Martin", "Christina Aguilera", "Christine Bleakley", "Clint Eastwood", "Clive Owen", "Coleen Rooney", "Colin Firth", "Dame Helen Mirren", "Dame Judi Dench", "Dame Julie Andrews", "Daniel Craig", "Daniel Day-Lewis", "Daniel Radcliffe", "David Beckham", "David Bowie", "David Bowie", "David Lloyd George", "David Tennant", "David Walliams", "Delia Smith", "Dick Cheney", "Donald Trump", "Eddie Izzard", "Eminem", "Emma Watson", "Emmeline Pankhurst", "Eric Clapton", "Eric Morecambe", "Fidel Castro", "Florence Nightingale", "Frank Lampard", "Freddie Flintoff", "Freddie Mercury", "Geoffrey Chaucer", "George Harrison", "George Michael", "George W. Bush", "Gordon Ramsay", "Graham Norton", "Guardian Journalists", "Guy Fawkes", "Harry Hill", "Heather Mills", "Hillary Rodham Clinton", "Hitler", "Holly Willoughby", "Hugh Grant", "Hugh Laurie", "Hulk Hogan", "James Corden", "Jamie Oliver", "Jane Austen", "Janet Jackson", "Jason Statham", "Jennifer Lopez", "Jensen Button", "Jeremy Clarkson", "Jeremy Paxman", "Jk Rowling", "JK Rowling OBE", "JLS", "John Logie Baird", "John Lydon", "John Peel", "Jonathan Ross", "JRR Tolkien", "Jude Law", "Kate Beckinsale", "Kate Middleton", "Kate Moss", "Kate Winslet", "Katherine Jenkins", "Katie Price", "Keira Knightley", "Keith Richards", "Kenneth Branagh", "King Arthur", "Kylie Minogue", "Lance Armstrong", "Leona Lewis", "Lewis Hamilton", "Liam Gallagher", "Lily Allen", "Lord Baden Powell", "Lord Lloyd Webber", "Lord Sugar", "Madonna", "Magic Johnson", "Marco Pierre White", "Margaret Thatcher", "Mariah Carey", "Marie Stopes", "MC Hammer", "Michael Crawford", "Michael Mcintyre", "Michael Sheen", "Mick Jagger", "Naomi Campbell", "Nicole Scherzinger", "Nigella Lawson", "Oprah Winfrey", "Ozzy Osbourne", "Paul McCartney", "Paul O'Grady", "Peter Kay", "Phillip Schofield", "Pope Benedict XVI", "Prince Harry", "Prince William", "Professor Stephen Hawking", "Professor Tim Berners Lee", "Queen Elizabeth", "Queen Victoria", "Richard Burton", "Ricky Gervais", "Rihanna", "Rio Ferdinand", "Robbie Williams", "Robert Pattinson", "Rod Stewart", "Ross Kemp", "Rowan Atkinson", "Russell Brand", "Sacha Baron Cohen", "Sarah Palin", "Shakira", "Sharon Osbourne", "Sienna Miller", "Silvio Berlusconi", "Simon Cowell", "Sir Alex Ferguson", "Sir Alexander Fleming", "Sir Alexander Graham", "Sir Anthony Hopkins", "Sir Cliff Richard", "Sir David Attenborough", "Sir Douglas Bader", "Sir Elton John", "Sir Francis Drake", "Sir Michael Caine", "Sir Paul McCartney", "Sir Richard Branson", "Sir Walter Raleigh", "Stella Mccartney", "Stephen Fry", "Susan Boyle", "Take That", "Taylor Swift", "Tony Benn", "Tony Blair", "Victoria Beckham", "Vinnie Jones", "Vladimir Putin", "Wayne Rooney", "William Blake", "Yoko Ono"}
	},
	{
		{"The"},
		{"Google Search", "Government Report", "Secret Documents", "Text Messages", "Faxes", "Leaked Video", "Sexy Video", "Shocking Tweet", "Amazing Information", "Life Hack", "Daily Mail Article", "True Story", "Unbelievable Story", "Redacted Documents", "Audio Recording", "Ancient Scrolls", "Hidden Comments In HTML", "Truth", "Lies", "Possible Facts", "Stuff We Made Up"},
		{"About"},
		{"Women", "Men", "Sausages", "Bacon", "Donkeys", "Muffins", "Twitter", "Tables", "Fascism", "The NHS", "The Secret Service", "Simon Le Bon", "Nigel Farage", "Dirty Harry", "Communists", "Su Pollard", "Graham Norton", "Tom Baker", "Brian Blessed", "Captain Sensible", "Kirsten Dunst", "Christians", "White People"},
		{"That"},
		{"Everyone", "No One", "Children", "Mens Rights Activists", "Environmentalists", "Eco-Warriors", "Lollipop Ladies", "Liberals", "School Teachers", "Firemen", "Doctors", "Nurses", "Labour Party Members", "Barry Gibb (out of the Bee Gees)", "Mormons", "Scientologists", "Suffragettes", "Devil Worshipers", "Doctor Who Fans", "CAMRA Members", "BBC Micro Owners", "Cosplay Enthusiasts", "Furries", "Sex Addicts", "White People"},
		{"Should", "Shouldn't"},
		{"See", "Click", "Get Angry About", "Retweet", "Ignore", "Send To Their Parents", "Applaud", "Tattoo On Their Face", "Nod At", "Sign A Petition Over", "See Before They Die", "See Before They're 30", "Fear", "Love", "Write To Their MP About"}
	},
	{
		{"3", "5", "7", "9", "11", "13", "15", "17", "19", "21", "23", "25", "27", "29", "31", "33", "35", "37", "39", "41", "43"},
		{"Weird", "Unusual", "Strange", "FIrst World", "Stupid", "Miserable", "Baffling", "Sexy", "White People's", "Big-Boobed", "Life Changing", "Rude", "Cat Related", "Orgasmic", "Dog Related", "Unbelievable", "Outragous", "Outlandish", "Libelous", "Badly Spelt", "Plagiarised"},
		{"Questions", "Problems", "Tips", "Life Hacks", "Twitterbots", "Maths Puzzles", "Chat-up Lines", "Novelty Dances", "Recipes", "Satanic Rituals", "Camping Tips", "Job Interview Questions", "Shed Hacks", "Insurance Claims", "Pubic Styles", "Denistry Tips", "Psychological Experiments", "Maths Puzzles", "Mind Games"},
		{"That Can't Be", "That Can Be", "That Will Be", "That Will Never Be"},
		{"Answered", "Solved", "Explained", "Fact Checked"},
		{"By Science", "By Doctors", "By Ghosts", "By British People", "By British Children", "By Getting Angry", "By Using Contraception", "By Listening To U2", "By Phoning Your Parents", "By Watching Ghostbusters", "By Hamsters", "By Traffic Wardens", "By Richard Dawkins", "By Bastards", "By Balloons", "By Capitalism", "By Cut'n'Paste Journalism", "By Chournalism", "By Screaming At A Wall", "By Your Doppleganger", "By Singing", "By Pretending To Be A Spider", "By Your Mum", "By The Girl Next Door", "By Clairvoyant Dogs", "By Tweets We Nicked Off The Internet", "By Stuff We Found On Reddit", "By Bee Gees Lyrics", "By Duran Duran B-Sides", "By Subtweeting", "By Your Dad"}
	},
	{
		{"3", "5", "7", "9", "11", "13", "15", "17", "19", "21"},
		{"Questions You Should Never Ask", "Bits Of Advice You Should Never Give", "Websites You Should Never Show To", "Articles On The Daily Mail You Should Never Tweet To", "Sex Toys You Shouldn't Use With", "Emojis That Would Upset", "Surprising Facts Learnt From Secretly Bugging", "Goats That Bleat Like", "Things You Should Never Say To", "Types of Fun You Should Never Have WIth"},
		{"A Tall Person", "A Short Person", "A Stupid Person", "A Glasses Wearer", "Bono (or U2)", "A Welshman", "A Sheep", "A Donkey", "A Pig", "A Screaming Child", "A Cub Scout Leader", "A Chef", "A Software Developer", "A Rockstar Programmer", "An Enthusiastic Hiker", "A Real Ale Enthusiast", "A Tree Surgeon", "A Marine Biologist", "A Sandwich Artist", "A College Professor", "A Fitness Enthusiast", "A Milkman (Or Woman)", "A Professional Clown", "An Amateur Clown", "A Freelance Nurse", "A Senior Citizen"}
	},
	{
		{"3", "5", "7", "9", "11", "13", "15", "17", "19", "21"},
		{"Things"},
		{"You'll Remember", "You'll Hate", "That'll Make You Explode With Rage", "That'll Make You Horny", "You'll Never Want To Hear Again", "You'll Never Forget", "You'll Only Remember", "You'll Never Admit", "That'll Make You Shake With Fear", "You'll Regret", "You'll Be Indifferent To", "You'll Be Embarrassed About", "You'll Be Perplexed By", "You'll Be Secretly Aroused By", "You'll Be Alarmed By", "You'll Be Sickened By"},
		{"If You"},
		{"Went", "Didn't Go"},
		{"To Wolverhampton University", "On A Gap Year", "To A Public School", "To A Comprehensive School", "On A French Holiday", "On Grindr", "On Tinder", "On OKCupid", "On MySpace", "To Eton", "To Brighton Polytechnic", "To London Transport Museum", "To Prison", "To Center Parcs"}
	},
	{
		{"This Video Will Prove You've Been"},
		{"Eating", "Peeling", "Biting", "Sniffing", "Cutting", "Weighing", "Buying", "Touching", "Shopping For", "Shop-Lifting", "Punching", "Slicing", "Juggling", "Cooking", "Boiling", "Frying", "Chopping"},
		{"Oranges", "Lemons", "Cakes", "Cucumbers", "Bacon", "Rabbits", "Ham", "Lettuce", "Grapes", "Food", "Scotch Eggs", "Hummus", "Cheese Triangles", "Creme Eggs", "Black Pudding", "Gravy", "Veggie-Burgers", "Cocopops", "Bovril", "Onions", "Chocolate Spread", "Marmalade", "Beef", "Chicken"},
		{"Wrong Your Whole Life!"}
	},
	{
		{"A Man", "A Woman", "A Child", "A Politican", "A Fireman", "An Ordinary Joe", "An Out Of Work Commedian", "A Single Mother", "A Dad", "A Parent", "A Scientist"},
		{"Tries To"},
		{"Hug", "Kiss", "Fight", "Cuddle", "Save", "Punch", "Make Love To", "Sell", "Purchase", "Make A Zoo For", "Predict The Future Of", "Buy", "Swap 50p For"},
		{"A"},
		{"Lion.", "Donkey.", "Fish.", "Fire Station.", "Fridge.", "Cup.", "Co-Worker.", "Bottle Of Beer.", "Leopard.", "Disney Princess.", "Baby.", "Cake.", "Bottle Of Coke.", "Bike.", "Hedgehog.", "Computer Game Character.", "Ghost."},
		{"The Reason Why Will Shock You!", "You Won't Believe What Happens Next", "First You'll Be Shocked, Then You'll Be Inspired", "The Reason Why Will Make You Cry"}
	},
	{
		{"This Boy", "This Girl", "This Child", "This Man", "This Woman", "This Robot"},
		{"Was Forced", "Was Asked", "Was Made"},
		{"To Leave"},
		{"School", "University", "Their Country", "Their Village", "A Shop", "A Supermarket", "A Cake Shop", "Twitter", "Facebook", "The Internet"},
		{"Due To Their"},
		{"Giant", "Small", "Upside-Down", "Inverted", "Back-To-Front", "Wrongly Coloured", "Wonky", "Suspicious"},
		{"Hands.", "Head.", "Feet.", "Arms.", "Lungs.", "Nose.", "Eyes.", "Fingers.", "Nipples.", "Elbows.", "Teeth.", "Nostrils.", "Eyebrows.", "Shins.", "Lips.", "Wrists.", "Forehead.", "Fangs."},
		{"You Won't Believe What Happens Next", "First You'll Be Shocked, Then You'll Be Inspired"}
	},
	{
		{"Was"},
		{"Abraham Lincoln", "Albert Einstein", "Alexander Graham Bell", "Alfred Hitchcock", "Aristotle", "Benjamin Franklin", "Bob Hope", "C. G. Jung", "C. S. Lewis", "Charles Dickens", "Charlie Brown", "Christopher Columbus", "Cleopatra", "Darth Vader", "Dr. Seuss", "Dwight D. Eisenhower", "Edgar Allen Poe", "Elizabeth Taylor", "Elvis Presley", "Ernest Hemingway", "Gandhi", "George Washington", "Helen Keller", "Henri Mancini", "Houdini", "Isaac Newton", "Jacqueline Kennedy Onasis", "James Dean", "Jane Austen", "John Candy", "John F. Kennedy", "John F. Kennedy, Jr.", "John Lennon", "Justin Timberlake", "Leonardo Da Vinci", "Lewis Carrol", "Liberace", "Louis Pasteur", "Ludwig van Beethoven", "Margaret Thatcher", "Marilyn Monroe", "Mark Twain", "Martin Luther King", "Michael Jackson", "Michael Jordan", "Michelangelo", "Mother Teresa", "Mozart", "Napoleon", "Neil Armstrong", "Pablo Piccaso", "Paul McCartney", "Plato", "Princess Diana", "Ray Charles", "Ronald Reagan", "Sigmund Freud", "Spider Man", "Thomas Edison", "Thomas Jefferson", "Tom Cruise", "Tommy Lee", "Vincent Van Gogh", "Walt Disney", "William F. Buckley, Jr.", "William Shakespeare"},
		{"Gay?", "A Satanist?", "A Paedophile?", "A Ghost?", "A Plagarist?", "A Racist?", "A Slave Trader?", "Born Without A Nose?", "A Bigot?", "An Anti-Semite?", "A Communist?", "A Stalinist?", "A Libertarian?", "A Marxist?", "A Homophobe?", "A Sexist?", "An Alien?", "A Socialist?"}
	}
}
return function()
	local ret = {}
	for _, words in ipairs(utils.random_choice(p)) do
		table.insert(ret, utils.random_choice(words))
	end
	return table.concat(ret, " ")
end