package dates

import (
	"time"
)

type Status string

const (
	StatusIdea      Status = "idea"
	StatusPlanned   Status = "planned"
	StatusCompleted Status = "completed"
	StatusArchived  Status = "archived"
)

type Vibe string

const (
	VibeEasy        Vibe = "easy"
	VibeClassic     Vibe = "classic"
	VibeSpontaneous Vibe = "spontaneous"
	VibeAdventure   Vibe = "adventure"
	VibeRelaxed     Vibe = "relaxed"
	VibeFancy       Vibe = "fancy"
)

type DatePlan struct {
	ID        string     `json:"id"`
	CoupleID  string     `json:"couple_id"`
	UserID    string     `json:"user_id"`
	Title     string     `json:"title"`
	Place     string     `json:"place"`
	Date      *time.Time `json:"date,omitempty"`
	Time      string     `json:"time,omitempty"`
	Vibe      Vibe       `json:"vibe"`
	Status    Status     `json:"status"`
	Notes     string     `json:"notes"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
}

type CuratedDate struct {
	ID          string   `json:"id"`
	Title       string   `json:"title"`
	Place       string   `json:"place"`
	Description string   `json:"description"`
	Vibe        Vibe     `json:"vibe"`
	Address     string   `json:"address,omitempty"`
	PriceRange  string   `json:"price_range,omitempty"` // "€", "€€", "€€€"
	Duration    string   `json:"duration,omitempty"`    // e.g., "2-3 hours"
	Tags        []string `json:"tags,omitempty"`
}

var WroclawCuratedDates = []CuratedDate{
	{
		ID:          "wro-1",
		Title:       "Sunset Walk on Ostrów Tumski",
		Place:       "Ostrów Tumski",
		Description: "Stroll through the oldest part of Wrocław with beautiful Gothic cathedral and evening lamplighter ceremony at dusk",
		Vibe:        VibeClassic,
		Address:     "Ostrów Tumski, 50-328 Wrocław",
		PriceRange:  "€",
		Duration:    "1-2 hours",
		Tags:        []string{"historic", "romantic", "walking", "architecture", "sunset"},
	},
	{
		ID:          "wro-2",
		Title:       "Picnic in Szczytnicki Park",
		Place:       "Szczytnicki Park & Japanese Garden",
		Description: "Grab some local food and enjoy a relaxed picnic in one of Poland's most beautiful parks, visit the Japanese Garden",
		Vibe:        VibeRelaxed,
		Address:     "pl. Grunwaldzki, 50-357 Wrocław",
		PriceRange:  "€",
		Duration:    "2-4 hours",
		Tags:        []string{"nature", "outdoor", "picnic", "relaxing", "garden"},
	},
	{
		ID:          "wro-3",
		Title:       "Dinner at Konspira Restaurant",
		Place:       "Konspira",
		Description: "Dine in a unique communist-era themed restaurant with authentic Polish cuisine in a bunker-like setting",
		Vibe:        VibeFancy,
		Address:     "Rynek 1, 50-106 Wrocław",
		PriceRange:  "€€",
		Duration:    "2-3 hours",
		Tags:        []string{"dinner", "historic", "unique", "polish-cuisine", "themed"},
	},
	{
		ID:          "wro-4",
		Title:       "Hunt for Wrocław Dwarfs",
		Place:       "Old Town",
		Description: "Search for the famous bronze dwarf statues scattered throughout the city - over 600 to discover!",
		Vibe:        VibeSpontaneous,
		Address:     "Rynek, 50-106 Wrocław",
		PriceRange:  "€",
		Duration:    "2-3 hours",
		Tags:        []string{"walking", "fun", "photo-op", "adventure", "unique"},
	},
	{
		ID:          "wro-5",
		Title:       "Cocktails at Mleczarnia",
		Place:       "Mleczarnia",
		Description: "Hip underground bar with creative cocktails, live music, and bohemian atmosphere in Nadodrze district",
		Vibe:        VibeEasy,
		Address:     "ul. Włodkowica 5, 50-072 Wrocław",
		PriceRange:  "€€",
		Duration:    "2-3 hours",
		Tags:        []string{"drinks", "nightlife", "music", "alternative", "cocktails"},
	},
	{
		ID:          "wro-6",
		Title:       "Kayaking on Odra River",
		Place:       "Odra River",
		Description: "Rent kayaks and paddle through the city's waterways, seeing Wrocław from a unique perspective",
		Vibe:        VibeAdventure,
		Address:     "Wybrzeże Wyspiańskiego, 50-370 Wrocław",
		PriceRange:  "€€",
		Duration:    "2-4 hours",
		Tags:        []string{"outdoor", "water-sports", "adventure", "active", "summer"},
	},
	{
		ID:          "wro-7",
		Title:       "Sky Tower Observation Deck",
		Place:       "Sky Tower",
		Description: "Visit the tallest building in Wrocław for panoramic city views from the 49th floor, best at sunset",
		Vibe:        VibeFancy,
		Address:     "pl. Powstańców Śląskich 95, 53-332 Wrocław",
		PriceRange:  "€",
		Duration:    "1-2 hours",
		Tags:        []string{"views", "panorama", "romantic", "modern", "sunset"},
	},
	{
		ID:          "wro-8",
		Title:       "Market Hall Food Tour",
		Place:       "Hala Targowa",
		Description: "Explore the historic covered market with local foods, cheeses, meats, and traditional Polish delicacies",
		Vibe:        VibeSpontaneous,
		Address:     "pl. Strzelecki 1, 50-224 Wrocław",
		PriceRange:  "€",
		Duration:    "1-2 hours",
		Tags:        []string{"food", "local", "market", "tasting", "authentic"},
	},
	{
		ID:          "wro-9",
		Title:       "Wrocław Zoo & Africarium",
		Place:       "Wrocław Zoo",
		Description: "Visit one of the largest zoos in Poland featuring the unique Africarium oceanarium with African marine life",
		Vibe:        VibeEasy,
		Address:     "ul. Wróblewskiego 1-5, 51-618 Wrocław",
		PriceRange:  "€€",
		Duration:    "3-5 hours",
		Tags:        []string{"animals", "educational", "family-friendly", "indoor", "aquarium"},
	},
	{
		ID:          "wro-10",
		Title:       "Coffee at Café Targowa",
		Place:       "Café Targowa",
		Description: "Specialty coffee in a beautifully restored historic building with exposed brick and cozy atmosphere",
		Vibe:        VibeRelaxed,
		Address:     "ul. Piłsudskiego 64, 50-020 Wrocław",
		PriceRange:  "€",
		Duration:    "1-2 hours",
		Tags:        []string{"coffee", "cafe", "relaxing", "conversation", "brunch"},
	},
	{
		ID:          "wro-11",
		Title:       "Racławice Panorama",
		Place:       "Panorama Racławicka",
		Description: "Experience the massive 360° painting depicting the Battle of Racławice - a unique artistic monument",
		Vibe:        VibeClassic,
		Address:     "ul. Jana Ewangelisty Purkyniego 11, 50-155 Wrocław",
		PriceRange:  "€",
		Duration:    "1-2 hours",
		Tags:        []string{"art", "history", "culture", "indoor", "unique"},
	},
	{
		ID:          "wro-12",
		Title:       "Rynek (Market Square) at Night",
		Place:       "Rynek - Main Market Square",
		Description: "Experience the stunning illuminated Gothic town hall and colorful townhouses, grab pierogi at a local spot",
		Vibe:        VibeClassic,
		Address:     "Rynek, 50-106 Wrocław",
		PriceRange:  "€",
		Duration:    "2-3 hours",
		Tags:        []string{"architecture", "historic", "food", "nighttime", "romantic"},
	},
	{
		ID:          "wro-13",
		Title:       "Botanical Garden Walk",
		Place:       "Botanical Garden",
		Description: "Peaceful stroll through diverse plant collections, greenhouses, and serene pathways near Ostrów Tumski",
		Vibe:        VibeRelaxed,
		Address:     "ul. Sienkiewicza 23, 50-335 Wrocław",
		PriceRange:  "€",
		Duration:    "1-2 hours",
		Tags:        []string{"nature", "garden", "peaceful", "outdoor", "flora"},
	},
	{
		ID:          "wro-14",
		Title:       "Cinema City for Movie Night",
		Place:       "Cinema City Wroclavia",
		Description: "Modern multiplex cinema in Wroclavia shopping center with comfortable VIP seats and latest releases",
		Vibe:        VibeEasy,
		Address:     "ul. Sucha 1, 50-086 Wrocław",
		PriceRange:  "€€",
		Duration:    "3-4 hours",
		Tags:        []string{"movies", "indoor", "entertainment", "relaxing", "classic-date"},
	},
	{
		ID:          "wro-15",
		Title:       "Escape Room Challenge",
		Place:       "Various Escape Rooms",
		Description: "Test your teamwork at one of Wrocław's many themed escape rooms - Lock.me, Questroom, or Escape2Win",
		Vibe:        VibeAdventure,
		Address:     "Multiple locations in city center",
		PriceRange:  "€€",
		Duration:    "1-2 hours",
		Tags:        []string{"puzzle", "teamwork", "indoor", "challenge", "fun"},
	},
	{
		ID:          "wro-16",
		Title:       "Craft Beer Tasting Tour",
		Place:       "Browar Stu Mostów",
		Description: "Visit Wrocław's famous craft brewery for tasting flights, brewery tour, and modern Polish pub food",
		Vibe:        VibeEasy,
		Address:     "ul. Grabiszyńska 242, 53-234 Wrocław",
		PriceRange:  "€€",
		Duration:    "2-3 hours",
		Tags:        []string{"beer", "tasting", "local", "food", "brewery"},
	},
	{
		ID:          "wro-17",
		Title:       "Hydropolis - Water Knowledge Center",
		Place:       "Hydropolis",
		Description: "Interactive science center about water in a restored 19th-century underground reservoir - unique and educational",
		Vibe:        VibeSpontaneous,
		Address:     "ul. Na Grobli 17, 50-421 Wrocław",
		PriceRange:  "€",
		Duration:    "2-3 hours",
		Tags:        []string{"science", "interactive", "indoor", "educational", "unique"},
	},
	{
		ID:          "wro-18",
		Title:       "Wine Bar at Whiskey in the Jar",
		Place:       "Whiskey in the Jar",
		Description: "Intimate wine and whiskey bar with extensive selection, knowledgeable staff, and cozy cellar atmosphere",
		Vibe:        VibeFancy,
		Address:     "ul. Świdnicka 53, 50-030 Wrocław",
		PriceRange:  "€€€",
		Duration:    "2-3 hours",
		Tags:        []string{"wine", "drinks", "intimate", "upscale", "evening"},
	},
}
