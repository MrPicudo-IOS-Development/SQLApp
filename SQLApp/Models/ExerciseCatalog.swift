//
//  ExerciseCatalog.swift -> SQLApp
//  Created by José Miguel Torres Chávez Nava on 19/03/26.
//

import Foundation

/// A non-instantiable catalog that holds every ``ExerciseBlock`` in the app.
///
/// Using a caseless `enum` prevents accidental instantiation while providing
/// a clear namespace for the exercise data. Add new blocks to the ``all``
/// array as the app grows — the rest of the architecture (seeding, navigation,
/// scoring) picks them up automatically.
enum ExerciseCatalog {
    
    /// All exercise blocks available in the app, in display order.
    static let exerciseBlocks: [ExerciseBlock] = [
        // MARK: - Block 1 · Dinosaurs
        ExerciseBlock(
            imageName: "E01Dinosaurs",
            sqlKeywords: ["SELECT", "FROM", "WHERE", "ORDER BY"],
            summary: "Query and filter prehistoric creatures by period, diet, and size.",
            tableNames: ["Dinosaurs"],
            jsonFileName: "dinosaursInfo",
            exercises: [
                Exercise(
                    title: "Meet the Giants",
                    instructions: "Write a query that returns the common_name and weight_kg of all dinosaurs. Order the results by weight_kg in descending order so the heaviest appear first.",
                    solutionSQL: "SELECT common_name, weight_kg FROM Dinosaurs ORDER BY weight_kg DESC"
                ),
                Exercise(
                    title: "Rulers of the Sky",
                    instructions: "Write a query that returns the common_name and fun_fact of all Aerial creatures.",
                    solutionSQL: "SELECT common_name, fun_fact FROM Dinosaurs WHERE domain = 'Aerial'"
                ),
                Exercise(
                    title: "The Plant Eaters",
                    instructions: "Write a query that returns the common_name, height_m, and length_m of all herbivores. Order the results by length_m in descending order.",
                    solutionSQL: "SELECT common_name, height_m, length_m FROM Dinosaurs WHERE diet = 'Herbivore' ORDER BY length_m DESC"
                ),
                Exercise(
                    title: "Who Lived the Longest?",
                    instructions: "Write a query that returns the common_name, domain, and avg_lifespan_yr of the 5 dinosaurs with the highest estimated lifespan. Order the results by avg_lifespan_yr in descending order.",
                    solutionSQL: "SELECT common_name, domain, avg_lifespan_yr FROM Dinosaurs ORDER BY avg_lifespan_yr DESC LIMIT 5"
                ),
                Exercise(
                    title: "Pocket-Sized Predators",
                    instructions: "Write a query that returns the common_name, weight_kg, and period of all carnivores that weigh less than 100 kg. Order the results by weight_kg in ascending order.",
                    solutionSQL: "SELECT common_name, weight_kg, period FROM Dinosaurs WHERE diet = 'Carnivore' AND weight_kg < 100 ORDER BY weight_kg ASC"
                ),
            ]
        ),
        
        // MARK: - Block 2 · Space missions
        ExerciseBlock(
            imageName: "E02Space",
            sqlKeywords: ["AND", "OR", "NOT", "IN", "BETWEEN", "LIKE", "IS NULL", "IS NOT NULL"],
            summary: "Filter space missions using logical operators, ranges, patterns, and null checks.",
            tableNames: ["SpaceMissions"],
            jsonFileName: "space",
            exercises: [
                Exercise(
                    title: "The Ongoing Voyages",
                    instructions: "Write a query that returns the mission_name, launch_year, and destination of all missions that are still active — meaning they have no end year recorded. Order the results by launch_year in ascending order.",
                    solutionSQL: "SELECT mission_name, launch_year, destination FROM SpaceMissions WHERE end_year IS NULL ORDER BY launch_year ASC"
                ),
                Exercise(
                    title: "Mars or the Moon?",
                    instructions: "Write a query that returns the mission_name, agency, and outcome of all missions whose destination is either 'Mars' or 'Moon'. Order the results by launch_year in descending order.",
                    solutionSQL: "SELECT mission_name, agency, outcome FROM SpaceMissions WHERE destination IN ('Mars', 'Moon') ORDER BY launch_year DESC"
                ),
                Exercise(
                    title: "The Golden Age of Exploration",
                    instructions: "Write a query that returns the mission_name, launch_year, and cost_million_usd of all missions launched between 2010 and 2023 that were successful. Order the results by cost_million_usd in descending order.",
                    solutionSQL: "SELECT mission_name, launch_year, cost_million_usd FROM SpaceMissions WHERE launch_year BETWEEN 2010 AND 2023 AND outcome = 'Success' ORDER BY cost_million_usd DESC"
                ),
                Exercise(
                    title: "Not Just NASA",
                    instructions: "Write a query that returns the mission_name, agency, country, and notable_achievement of all successful missions that were NOT launched by NASA. Order the results by launch_year in ascending order.",
                    solutionSQL: "SELECT mission_name, agency, country, notable_achievement FROM SpaceMissions WHERE outcome = 'Success' AND agency != 'NASA' ORDER BY launch_year ASC"
                ),
                Exercise(
                    title: "Voyagers and Rovers",
                    instructions: "Write a query that returns the mission_name, destination, and cost_million_usd of all missions whose name contains 'Voyager' or whose mission_type is like '%Rover'. Show only those with a known cost. Order the results by cost_million_usd in descending order.",
                    solutionSQL: "SELECT mission_name, destination, cost_million_usd FROM SpaceMissions WHERE (mission_name LIKE '%Voyager%' OR mission_type LIKE '%Rover') AND cost_million_usd IS NOT NULL ORDER BY cost_million_usd DESC"
                ),
            ]
        ),
        
        // MARK: - Block 3 · Movies and cinema
        ExerciseBlock(
            imageName: "E03Movies",
            sqlKeywords: ["COUNT", "SUM", "AVG", "MIN", "MAX", "GROUP BY", "HAVING", "ROUND"],
            summary: "Aggregate and summarize film data by genre, country, director, and box office performance.",
            tableNames: ["Movies"],
            jsonFileName: "movies",
            exercises: [
                Exercise(
                    title: "Hollywood by the Numbers",
                    instructions: "Write a query that returns the genre, the number of movies in each genre as movie_count, and the average IMDb rating rounded to one decimal place as avg_rating. Group the results by genre and order them by movie_count in descending order.",
                    solutionSQL: "SELECT genre, COUNT(*) AS movie_count, ROUND(AVG(imdb_rating), 1) AS avg_rating FROM Movies GROUP BY genre ORDER BY movie_count DESC"
                ),
                Exercise(
                    title: "The Billion Dollar Club",
                    instructions: "Write a query that returns the title, budget_million_usd, box_office_million_usd, and the return on investment rounded to one decimal place as roi. Calculate ROI as box_office divided by budget. Show only movies where the box office exceeded 1000 million. Order by roi in descending order.",
                    solutionSQL: "SELECT title, budget_million_usd, box_office_million_usd, ROUND(box_office_million_usd / budget_million_usd, 1) AS roi FROM Movies WHERE box_office_million_usd > 1000 ORDER BY roi DESC"
                ),
                Exercise(
                    title: "Oscar Powerhouses",
                    instructions: "Write a query that returns the director, the number of movies as num_films, the total Oscar nominations as total_nominations, and the total Oscars won as total_wins. Only include directors who have more than one movie in the table. Order by total_wins in descending order.",
                    solutionSQL: "SELECT director, COUNT(*) AS num_films, SUM(oscar_nominations) AS total_nominations, SUM(oscars_won) AS total_wins FROM Movies GROUP BY director HAVING COUNT(*) > 1 ORDER BY total_wins DESC"
                ),
                Exercise(
                    title: "Streaming Wars",
                    instructions: "Write a query that returns the streaming_platform, the number of movies as catalog_size, the minimum and maximum IMDb ratings as lowest_rating and highest_rating, and the total box office revenue rounded to zero decimal places as total_box_office. Group by platform and show only platforms with 3 or more movies. Order by total_box_office in descending order.",
                    solutionSQL: "SELECT streaming_platform, COUNT(*) AS catalog_size, MIN(imdb_rating) AS lowest_rating, MAX(imdb_rating) AS highest_rating, ROUND(SUM(box_office_million_usd), 0) AS total_box_office FROM Movies GROUP BY streaming_platform HAVING COUNT(*) >= 3 ORDER BY total_box_office DESC"
                ),
                Exercise(
                    title: "Global Cinema Gems",
                    instructions: "Write a query that returns the country, the number of movies as num_movies, the average budget rounded to one decimal place as avg_budget, and the average Rotten Tomatoes percentage rounded to zero decimal places as avg_rt_score. Only include movies released from the year 2000 onward and that are not in English. Group by country and order by avg_rt_score in descending order.",
                    solutionSQL: "SELECT country, COUNT(*) AS num_movies, ROUND(AVG(budget_million_usd), 1) AS avg_budget, ROUND(AVG(rotten_tomatoes_pct), 0) AS avg_rt_score FROM Movies WHERE release_year >= 2000 AND language != 'English' GROUP BY country ORDER BY avg_rt_score DESC"
                ),
            ]
        ),
        
        // MARK: - Block 4 · Videogames
        ExerciseBlock(
            imageName: "E04Videogames",
            sqlKeywords: ["INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "ON"],
            summary: "Combine studios, games, and platforms to explore relationships across the gaming industry.",
            tableNames: ["Studios", "VideoGames", "GamePlatforms"],
            jsonFileName: "videogames",
            exercises: [
                Exercise(
                    title: "Who Made What",
                    instructions: "Write a query that returns the studio name, the game title, and the metacritic_score for every game. Join the Studios and VideoGames tables. Order the results by metacritic_score in descending order, and limit to the top 10.",
                    solutionSQL: "SELECT s.name, v.title, v.metacritic_score FROM VideoGames v INNER JOIN Studios s ON v.id_studio = s.id ORDER BY v.metacritic_score DESC LIMIT 10"
                ),
                Exercise(
                    title: "Platform Count",
                    instructions: "Write a query that returns each game title and the number of platforms it was released on as num_platforms. Join VideoGames with GamePlatforms. Order by num_platforms in descending order.",
                    solutionSQL: "SELECT v.title, COUNT(*) AS num_platforms FROM VideoGames v INNER JOIN GamePlatforms gp ON v.id = gp.id_game GROUP BY v.title ORDER BY num_platforms DESC"
                ),
                Exercise(
                    title: "Independent Hits",
                    instructions: "Write a query that returns the studio name, the game title, and copies_sold_million for all games made by independent studios. Join Studios and VideoGames, and filter where the studio is independent. Order by copies_sold_million in descending order.",
                    solutionSQL: "SELECT s.name, v.title, v.copies_sold_million FROM VideoGames v INNER JOIN Studios s ON v.id_studio = s.id WHERE s.is_independent = TRUE ORDER BY v.copies_sold_million DESC"
                ),
                Exercise(
                    title: "The Full Picture",
                    instructions: "Write a query that returns the studio name, its country, the number of games as total_games, and the total copies sold across all their games rounded to two decimal places as total_copies_million. Use LEFT JOIN from Studios to VideoGames so that studios with no games still appear. Group by studio name and country. Order by total_copies_million in descending order.",
                    solutionSQL: "SELECT s.name, s.country, COUNT(v.id) AS total_games, ROUND(SUM(v.copies_sold_million), 2) AS total_copies_million FROM Studios s LEFT JOIN VideoGames v ON s.id = v.id_studio GROUP BY s.name, s.country ORDER BY total_copies_million DESC"
                ),
                Exercise(
                    title: "Triple Join: Studio to Screen",
                    instructions: "Write a query that returns the studio name, the game title, the platform, and the price_usd. Join all three tables: Studios to VideoGames, and VideoGames to GamePlatforms. Show only games with a metacritic_score of 93 or higher and a price_usd below 60.00. Order by studio name in ascending order, then by price_usd in ascending order.",
                    solutionSQL: "SELECT s.name, v.title, gp.platform, gp.price_usd FROM VideoGames v INNER JOIN Studios s ON v.id_studio = s.id INNER JOIN GamePlatforms gp ON v.id = gp.id_game WHERE v.metacritic_score >= 93 AND gp.price_usd < 60.00 ORDER BY s.name ASC, gp.price_usd ASC"
                ),
            ]
        ),
        
        // MARK: - Block 5 · Olympics
        ExerciseBlock(
            imageName: "E05Olympics",
            sqlKeywords: ["Subquery", "EXISTS", "NOT EXISTS", "ANY", "ALL", "FULL OUTER JOIN", "CROSS JOIN"],
            summary: "Use subqueries and advanced joins to uncover patterns across athletes, competitions, and medals.",
            tableNames: ["Athletes", "Competitions", "Medals"],
            jsonFileName: "olympics",
            exercises: [
                Exercise(
                    title: "Record Breakers",
                    instructions: "Write a query that returns the full_name, country, and sport of athletes who won a medal in a competition where a world record was set. Use a subquery to first find the competition IDs where world_record_set is true, then filter medals by those IDs. Order by full_name in ascending order.",
                    solutionSQL: "SELECT DISTINCT a.full_name, a.country, a.sport FROM Athletes a INNER JOIN Medals m ON a.id = m.id_athlete WHERE m.id_competition IN (SELECT id FROM Competitions WHERE world_record_set = TRUE) ORDER BY a.full_name ASC"
                ),
                Exercise(
                    title: "The Silent Ones",
                    instructions: "Write a query that returns the full_name, country, and sport of all athletes who have NOT won any medal. Use NOT EXISTS with a subquery that checks the Medals table. Order by full_name in ascending order.",
                    solutionSQL: "SELECT a.full_name, a.country, a.sport FROM Athletes a WHERE NOT EXISTS (SELECT 1 FROM Medals m WHERE m.id_athlete = a.id) ORDER BY a.full_name ASC"
                ),
                Exercise(
                    title: "Above the Average",
                    instructions: "Write a query that returns the full_name, sport, and height_cm of athletes who are taller than the average height of all athletes. Use a subquery to calculate the average. Show only athletes whose height is not null. Order by height_cm in descending order.",
                    solutionSQL: "SELECT full_name, sport, height_cm FROM Athletes WHERE height_cm IS NOT NULL AND height_cm > (SELECT AVG(height_cm) FROM Athletes WHERE height_cm IS NOT NULL) ORDER BY height_cm DESC"
                ),
                Exercise(
                    title: "Medal Count per Nation",
                    instructions: "Write a query that uses a subquery in FROM to first count the total medals per athlete, then returns each country, the number of medalists as num_medalists, and the average medals per athlete rounded to one decimal place as avg_medals_per_athlete. Group by country and show only countries with more than 2 medalists. Order by avg_medals_per_athlete in descending order.",
                    solutionSQL: "SELECT athlete_medals.country, COUNT(*) AS num_medalists, ROUND(AVG(athlete_medals.medal_count), 1) AS avg_medals_per_athlete FROM (SELECT a.country, a.id, COUNT(*) AS medal_count FROM Athletes a INNER JOIN Medals m ON a.id = m.id_athlete GROUP BY a.country, a.id) AS athlete_medals GROUP BY athlete_medals.country HAVING COUNT(*) > 2 ORDER BY avg_medals_per_athlete DESC"
                ),
                Exercise(
                    title: "Gold Dominance",
                    instructions: "Write a query that returns the full_name, country, and sport of athletes whose total number of gold medals is greater than or equal to ALL other athletes' gold medal counts. Use a subquery with ALL to compare. Consider only medals where medal_type is 'Gold'.",
                    solutionSQL: "SELECT a.full_name, a.country, a.sport FROM Athletes a INNER JOIN Medals m ON a.id = m.id_athlete WHERE m.medal_type = 'Gold' GROUP BY a.id, a.full_name, a.country, a.sport HAVING COUNT(*) >= ALL (SELECT COUNT(*) FROM Medals WHERE medal_type = 'Gold' GROUP BY id_athlete)"
                ),
            ]
        )
    ]
}
