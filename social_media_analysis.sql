/* =====================================================================
   SOCIAL MEDIA (IG CLONE) — STUDENT ANSWER TEMPLATE
   ===================================================================== */

USE ig_clone;


/* =====================================================================
   OBJECTIVE QUESTIONS
   ===================================================================== */

-- O1.
-- Are there any tables with duplicate or missing null values? If so, how
-- would you handle them?

SELECT 'users', COUNT(*) - COUNT(DISTINCT id) AS Duplicates, SUM(username IS NULL) AS NullValues FROM users
UNION ALL
SELECT 'photos', COUNT(*) - COUNT(DISTINCT id), SUM(image_url IS NULL) FROM photos
UNION ALL
SELECT 'comments', COUNT(*) - COUNT(DISTINCT id), SUM(comment_text IS NULL) FROM comments
UNION ALL
SELECT 'likes', COUNT(*) - COUNT(DISTINCT user_id, photo_id), 0 FROM likes
UNION ALL
SELECT 'follows', COUNT(*) - COUNT(DISTINCT follower_id, followee_id), 0 FROM follows
UNION ALL
SELECT 'photo_tags', COUNT(*) - COUNT(DISTINCT photo_id, tag_id), 0 FROM photo_tags
UNION ALL
SELECT 'tags', COUNT(*) - COUNT(DISTINCT id), SUM(id IS NULL) FROM tags;

-- O2.
-- What is the distribution of user activity levels (e.g., number of posts,
-- likes, comments) across the user base?

WITH user_photos AS (
    SELECT 
        user_id,
        COUNT(id) AS total_posts
    FROM photos
    GROUP BY user_id
),
user_tags AS (
    SELECT 
        p.user_id,
        COUNT(DISTINCT pt.tag_id) AS total_tags
    FROM photos p
    INNER JOIN photo_tags pt 
        ON p.id = pt.photo_id
    GROUP BY p.user_id
),
user_comments AS (
    SELECT 
        user_id,
        COUNT(id) AS total_comments
    FROM comments
    GROUP BY user_id
),
user_likes AS (
    SELECT 
        user_id,
        COUNT(*) AS total_likes
    FROM likes
    GROUP BY user_id
)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(up.total_posts, 0) AS photos_posted,
    COALESCE(ut.total_tags, 0) AS tags_used,
    COALESCE(uc.total_comments, 0) AS comments_made,
    COALESCE(ul.total_likes, 0) AS likes_given
FROM users u
LEFT JOIN user_photos up 
    ON u.id = up.user_id
LEFT JOIN user_tags ut 
    ON u.id = ut.user_id
LEFT JOIN user_comments uc 
    ON u.id = uc.user_id
LEFT JOIN user_likes ul 
    ON u.id = ul.user_id
ORDER BY u.id;

-- O3.
-- Calculate the average number of tags per post (photo_tags and photos
-- tables).

SELECT 
    ROUND(AVG(tag_count), 2) as avg_tags_per_post
FROM (SELECT 
    p.id,
    COUNT(pt.tag_id) as tag_count
FROM photos p
LEFT JOIN photo_tags pt ON p.id = pt.photo_id
GROUP BY p.id
) as post_tags;

-- O4.
-- Identify the top users with the highest engagement rates (likes, comments)
-- on their posts and rank them.

WITH engagement AS (
    SELECT 
        u.id,
        u.username,
        p.id AS photo_id,
        COUNT(DISTINCT l.user_id) AS likes,
        COUNT(DISTINCT c.user_id) AS comments
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    JOIN likes l ON l.photo_id = p.id
    JOIN comments c ON c.photo_id = p.id
    GROUP BY u.id, u.username, p.id
)
SELECT 
    id,
    username,
    SUM(likes + comments) AS total_engagement,
    DENSE_RANK() OVER (ORDER BY SUM(likes + comments) DESC) AS engagement_rank
FROM engagement
GROUP BY id, username;

-- O5.
-- Which users have the highest number of followers and followings?

(SELECT 
    'Most Followed' AS Category,
    followee_id AS UserID,
    COUNT(*) AS Total
FROM follows
GROUP BY followee_id
ORDER BY Total DESC
LIMIT 5)

UNION ALL

(SELECT 
    'Most Following' AS Category,
    follower_id AS UserID,
    COUNT(*) AS Total
FROM follows
GROUP BY follower_id
ORDER BY Total DESC
LIMIT 5);

-- O6.
-- Calculate the average engagement rate (likes, comments) per post for each
-- user.

SELECT 
	u.id,
	u.username, 
	round(AVG(
		(SELECT 
			COUNT(*) 
		FROM likes l 
        WHERE l.photo_id = p.id) 
        +(SELECT 
			COUNT(*) 
		FROM comments c 
       WHERE c.photo_id = p.id)),2) AS AvgEngagementPerPost
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
GROUP BY u.id, u.username
ORDER BY AvgEngagementPerPost DESC;

-- O7.
-- Get the list of users who have never liked any post (users and likes
-- tables)

SELECT
	u.id,
    u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- O8.
-- How can you leverage user-generated content (posts, hashtags, photo tags)
-- to create more personalized and engaging ad campaigns?

SELECT
    tag_name,
    COUNT(pt.photo_id) AS num_posts,
    COUNT(DISTINCT p.user_id) AS num_users,
    COUNT(l.photo_id) AS num_likes,
    (
        COUNT(pt.photo_id) +
        COUNT(DISTINCT p.user_id) +
        COUNT(l.photo_id)
    ) AS total_engagement_per_tag
FROM photos p
JOIN photo_tags pt ON p.id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
JOIN likes l ON p.id = l.photo_id
GROUP BY t.id, t.tag_name
ORDER BY num_posts DESC, num_users DESC;

-- O9.
-- Are there any correlations between user activity levels and specific
-- content types (e.g., photos, videos, reels)? How can this information
-- guide content creation and curation strategies?

WITH photo_counts AS (
    SELECT user_id, COUNT(*) AS photo_uploads
    FROM photos
    GROUP BY user_id
),
engagement_counts AS (
    
    SELECT 
        p.user_id,
        COUNT(l.photo_id) AS total_likes,
        COUNT(c.id) AS total_comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
)
SELECT
    u.id AS user_id,
    u.username,
    COALESCE(pc.photo_uploads, 0) AS photo_uploads,
    COALESCE(ec.total_likes, 0) AS total_likes,
    COALESCE(ec.total_comments, 0) AS total_comments
FROM users u
LEFT JOIN photo_counts pc ON u.id = pc.user_id
LEFT JOIN engagement_counts ec ON u.id = ec.user_id
ORDER BY u.id;

-- CORRELATION BETWEEN NO. OF UPLOADS AND TOTAL_ENGAGEMENT
SELECT 
    photo_uploads,
    ROUND(AVG(total_engagement), 0) AS average_engagement
FROM (
    SELECT 
        u.id,
        
        (SELECT COUNT(*) FROM photos p WHERE p.user_id = u.id) AS photo_uploads,
       
        (
            SELECT COUNT(*) FROM likes l 
            WHERE l.photo_id IN (SELECT id FROM photos WHERE user_id = u.id)
        ) + 
        (
            SELECT COUNT(*) FROM comments c 
            WHERE c.photo_id IN (SELECT id FROM photos WHERE user_id = u.id)
        ) AS total_engagement
    FROM users u
) user_metrics
WHERE photo_uploads > 0
GROUP BY photo_uploads
ORDER BY photo_uploads;

-- O10.
-- Calculate the total number of likes, comments, and photo tags for each
-- user.

WITH User_responses as
 (
	SELECT 
		u.id AS user_id,
        u.username, p.id AS photo_id,
	    COUNT(DISTINCT l.user_id) AS likes,
	    COUNT(DISTINCT c.id) AS comments,
	    COUNT(DISTINCT pt.tag_id) AS tags
	FROM users u 
	JOIN photos p ON u.id = p.user_id
	JOIN photo_tags pt ON p.id = pt.photo_id
	JOIN likes l ON pt.photo_id = l.photo_id
	JOIN comments c ON pt.photo_id = c.photo_id
	GROUP BY u.id, u.username, p.id
) 
SELECT 
		user_id, 
        username, 
       SUM(likes) AS likes,
       SUM(comments) AS comments,
       SUM(tags) AS tags
FROM User_responses
GROUP BY user_id, username;

-- O11.
-- Rank users based on their total engagement (likes, comments, shares) over a
-- month.

WITH recent_photos AS (
    
    SELECT
		id,
        user_id, 
        created_dat
    FROM photos
    WHERE created_dat >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
),
like_counts AS (
   
    SELECT 
		photo_id, 
        COUNT(*) AS likes_count
    FROM likes
    WHERE photo_id IN (SELECT id FROM recent_photos)
    GROUP BY photo_id
),
comment_counts AS (
   
    SELECT 
		photo_id, 
        COUNT(*) AS comments_count
    FROM comments
    WHERE photo_id IN (SELECT id FROM recent_photos)
    GROUP BY photo_id
),
user_monthly_stats AS (
    
    SELECT 
        u.id AS user_id,
        u.username,
        YEAR(p.created_dat) AS year,
        MONTH(p.created_dat) AS month,
        SUM(COALESCE(l.likes_count, 0)) AS total_likes,
        SUM(COALESCE(c.comments_count, 0)) AS total_comments
    FROM users u
    JOIN recent_photos p ON u.id = p.user_id
    LEFT JOIN like_counts l ON p.id = l.photo_id
    LEFT JOIN comment_counts c ON p.id = c.photo_id
    GROUP BY u.id, u.username, year, month
)
SELECT
    user_id,
    username,
    year,
    month,
    (total_likes + total_comments) AS total_engagement,
    RANK() OVER (ORDER BY (total_likes + total_comments) DESC) AS engagement_rank
FROM user_monthly_stats
ORDER BY engagement_rank ;

-- O12.
-- Retrieve the hashtags that have been used in posts with the highest average
-- number of likes. Use a CTE to calculate the average likes for each
-- hashtag first.

WITH HashtagLikes AS (
    SELECT 
		t.tag_name, 
        round(AVG(l_count.likes),2) AS AvgLikes
    FROM photo_tags pt JOIN tags t 
    ON pt.tag_id = t.id
    JOIN (SELECT 
			photo_id,
            COUNT(*) AS likes 
		  FROM likes 
          GROUP BY photo_id) l_count
    ON pt.photo_id = l_count.photo_id
    GROUP BY t.tag_name
)
SELECT * FROM HashtagLikes ORDER BY AvgLikes DESC LIMIT 10;

-- O13.
-- Retrieve the users who have started following someone after being followed
-- by that person.

SELECT 
    f1.follower_id AS followed_user_id,
    u1.username AS followed_user,
    f1.followee_id AS started_following_user_id,
    u2.username AS starting_following_user
FROM 
    follows f1
JOIN 
    follows f2 
    ON f1.follower_id = f2.followee_id AND f1.followee_id = f2.follower_id
JOIN 
    users u1 
    ON f1.follower_id = u1.id
JOIN 
    users u2 
    ON f1.followee_id = u2.id
WHERE 
    f1.created_at >= f2.created_at;


/* =====================================================================
   SUBJECTIVE QUESTIONS
   ===================================================================== */

-- S1.
-- Based on user engagement and activity levels, which users would you
-- consider the most loyal or valuable? How would you reward or incentivize
-- these users?

WITH PhotosPosted AS (
    
    SELECT user_id, COUNT(id) AS total_photos_posted
    FROM photos
    GROUP BY user_id
),
TotalLikes AS (
    SELECT user_id, COUNT(photo_id) AS total_likes 
    FROM likes 
    WHERE user_id IN (SELECT user_id FROM PhotosPosted)
    GROUP BY user_id
),
TotalComments AS (
    SELECT user_id, COUNT(id) AS total_comments 
    FROM comments 
    WHERE user_id IN (SELECT user_id FROM PhotosPosted)
    GROUP BY user_id
),
Followers AS (
    SELECT followee_id AS user_id, COUNT(follower_id) AS total_followers
    FROM follows
    WHERE followee_id IN (SELECT user_id FROM PhotosPosted)
    GROUP BY followee_id
),
UniqueTags AS (
    SELECT p.user_id, COUNT(DISTINCT pt.tag_id) AS unique_tags_used
    FROM photos p
    JOIN photo_tags pt ON p.id = pt.photo_id
    WHERE p.user_id IN (SELECT user_id FROM PhotosPosted)
    GROUP BY p.user_id
)
SELECT 
    u.id AS user_id, 
    u.username,
    COALESCE(tl.total_likes, 0) AS total_likes,
    COALESCE(tc.total_comments, 0) AS total_comments,
    pp.total_photos_posted,
    COALESCE(f.total_followers, 0) AS total_followers,
    COALESCE(ut.unique_tags_used, 0) AS unique_tags_used,
    (COALESCE(tl.total_likes, 0) + COALESCE(tc.total_comments, 0)) AS total_engagement
FROM users u
INNER JOIN PhotosPosted pp ON u.id = pp.user_id 
LEFT JOIN TotalLikes tl ON u.id = tl.user_id
LEFT JOIN TotalComments tc ON u.id = tc.user_id
LEFT JOIN Followers f ON u.id = f.user_id
LEFT JOIN UniqueTags ut ON u.id = ut.user_id
ORDER BY total_engagement DESC, total_followers DESC, total_photos_posted DESC
LIMIT 10;

-- S2.
-- For inactive users, what strategies would you recommend to re-engage them
-- and encourage them to start posting or engaging again?

WITH photo_counts AS (
    
    SELECT user_id, COUNT(*) AS num_of_photos
    FROM photos
    GROUP BY user_id
),
likes_count AS (
    SELECT user_id, COUNT(*) AS num_of_likes
    FROM likes
    GROUP BY user_id
),
comments_count AS (
    SELECT user_id, COUNT(id) AS num_of_comments
    FROM comments
    GROUP BY user_id
),
phototags_count AS (
    
    SELECT p.user_id, COUNT(pt.tag_id) AS num_of_phototags
    FROM photos p
    INNER JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.user_id
),
follower_stats AS (
   
    SELECT 
        u.id AS user_id,
        (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS follower_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) AS followee_count
    FROM users u
)
SELECT
    u.id AS UserID,
    u.username AS UserName,
    COALESCE(l.num_of_likes, 0) AS num_of_likes,
    COALESCE(c.num_of_comments, 0) AS num_of_comments,
    COALESCE(pp.num_of_photos, 0) AS num_of_photos,
    COALESCE(pt.num_of_phototags, 0) AS num_of_phototags,
    COALESCE(fs.follower_count, 0) AS follower_count,
    COALESCE(fs.followee_count, 0) AS followee_count,
    -- Pre-calculate engagement to keep the DENSE_RANK clean
    (COALESCE(l.num_of_likes, 0) + COALESCE(c.num_of_comments, 0) + COALESCE(pp.num_of_photos, 0)) AS engagement_score,
    DENSE_RANK() OVER (
        ORDER BY (COALESCE(l.num_of_likes, 0) + COALESCE(c.num_of_comments, 0) + COALESCE(pp.num_of_photos, 0)) ASC
    ) AS engagement_rank
FROM users u
LEFT JOIN likes_count l ON u.id = l.user_id
LEFT JOIN comments_count c ON u.id = c.user_id
LEFT JOIN photo_counts pp ON u.id = pp.user_id
LEFT JOIN phototags_count pt ON u.id = pt.user_id
LEFT JOIN follower_stats fs ON u.id = fs.user_id
ORDER BY engagement_rank ASC;

-- S3.
-- Which hashtags or content topics have the highest engagement rates? How can
-- this information guide content strategy and ad campaigns?

SELECT
    t.tag_name,
    COUNT(pt.photo_id) AS total_posts,
    COALESCE(SUM(likes.total_likes), 0) AS total_likes,
    COALESCE(SUM(comments.total_comments), 0) AS total_comments,
    (COALESCE(SUM(likes.total_likes), 0) + COALESCE(SUM(comments.total_comments), 0)) / COUNT(pt.photo_id) AS average_engagement
FROM
    tags t
JOIN
    photo_tags pt ON t.id = pt.tag_id
LEFT JOIN
    (SELECT photo_id, COUNT(*) AS total_likes FROM likes GROUP BY photo_id) likes ON pt.photo_id = likes.photo_id
LEFT JOIN
    (SELECT photo_id, COUNT(*) AS total_comments FROM comments GROUP BY photo_id) comments ON pt.photo_id = comments.photo_id
GROUP BY
    t.tag_name
ORDER BY
    average_engagement DESC
LIMIT 10;

-- S4.
-- Are there any patterns or trends in user engagement based on demographics
-- (age, location, gender) or posting times? How can these insights inform
-- targeted marketing campaigns?

-- Query 1: Joining Year, Follower Count, and Engagement Patterns
SELECT 
    joining_year,
    follower_count,
    COUNT(user_id) AS user_count,
    ROUND(AVG(post_count), 0) AS avg_post,
    ROUND(AVG(engagement_received), 2) AS avg_engagement
FROM (
    SELECT 
        u.id AS user_id,
        YEAR(u.created_at) AS joining_year,
        -- Get follower count independently
        (SELECT COUNT(*) FROM follows f WHERE f.followee_id = u.id) AS follower_count,
        -- Get post count independently
        (SELECT COUNT(*) FROM photos p WHERE p.user_id = u.id) AS post_count,
        -- Get engagement independently to avoid join explosion
        (SELECT COUNT(*) FROM comments c WHERE c.photo_id IN (SELECT id FROM photos WHERE user_id = u.id)) +
        (SELECT COUNT(*) FROM likes l WHERE l.photo_id IN (SELECT id FROM photos WHERE user_id = u.id)) AS engagement_received
    FROM users u
) z
GROUP BY joining_year, follower_count;

-- Query 2: Tag Usage and Content Preferences
WITH tag_counts AS (

    SELECT 
        YEAR(u.created_at) AS joining_year,
        t.tag_name,
        COUNT(u.id) AS user_count
    FROM users u
    INNER JOIN photos p ON u.id = p.user_id
    INNER JOIN photo_tags pt ON p.id = pt.photo_id
    INNER JOIN tags t ON pt.tag_id = t.id
    GROUP BY YEAR(u.created_at), t.tag_name
),
tag_ranking AS (
    
    SELECT 
        joining_year,
        tag_name,
        user_count,
        DENSE_RANK() OVER(PARTITION BY joining_year ORDER BY user_count DESC) AS rnk
    FROM tag_counts
)
SELECT 
    joining_year,
    tag_name,
    user_count
FROM tag_ranking
WHERE rnk <= 5
ORDER BY joining_year DESC, user_count DESC;

-- S5.
-- Based on follower counts and engagement rates, which users would be ideal
-- candidates for influencer marketing campaigns? How would you approach
-- and collaborate with these influencers?

WITH top_followers AS (
    
    SELECT 
        followee_id AS user_id, 
        COUNT(*) AS follower_count
    FROM follows
    GROUP BY followee_id
    HAVING COUNT(*) = (
        SELECT COUNT(*) FROM follows GROUP BY followee_id ORDER BY 1 DESC LIMIT 1
    )
),
metrics AS (
    
    SELECT 
        u.id, 
        u.username,
        tf.follower_count,
        (SELECT COUNT(*) FROM photos WHERE user_id = u.id) AS posts_count,
        (SELECT COUNT(DISTINCT photo_id) FROM likes WHERE user_id = u.id) AS likes_count,
        (SELECT COUNT(*) FROM comments WHERE user_id = u.id) AS comments_count
    FROM users u
    JOIN top_followers tf ON u.id = tf.user_id
),
total_pool AS (
    
    SELECT SUM(activity) as global_sum
    FROM (
        SELECT (SELECT COUNT(*) FROM photos) + (SELECT COUNT(*) FROM likes) + (SELECT COUNT(*) FROM comments) as activity
    ) t
)
SELECT 
    m.username,
    ((m.posts_count + m.likes_count + m.comments_count) * 100.0 / NULLIF(tp.global_sum, 0)) AS engagement_rate,
    m.follower_count,
    round((((m.posts_count + m.likes_count + m.comments_count) * 100.0 / NULLIF(tp.global_sum, 0)) * 0.6 + m.follower_count * 0.4),2) AS weighted_score
FROM metrics m, total_pool tp
WHERE (m.posts_count + m.likes_count + m.comments_count) > 0
ORDER BY weighted_score DESC;

-- S6.
-- Based on user behavior and engagement data, how would you segment the user
-- base for targeted marketing campaigns or personalized recommendations?

SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,
    COALESCE(p.total_photos, 0) AS total_photos,
    
    CASE 
        WHEN COALESCE(p.total_photos, 0) = 0 THEN 0 
        ELSE round((COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 1.0 / p.total_photos,2)
    END AS engagement_rate,
    
    CASE 
        WHEN COALESCE(p.total_photos, 0) = 0 THEN 'Low'
        WHEN (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 1.0 / p.total_photos > 150 THEN 'High'
        WHEN (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 1.0 / p.total_photos BETWEEN 100 AND 150 THEN 'Medium'
        ELSE 'Low'
    END AS engagement_level
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_likes FROM likes GROUP BY user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_comments FROM comments GROUP BY user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_photos FROM photos GROUP BY user_id
) p ON u.id = p.user_id
ORDER BY engagement_rate DESC;

-- S7.
-- If data on ad campaigns (impressions, clicks, conversions) is available,
-- how would you measure their effectiveness and optimize future campaigns?

-- ****** Answered in the Project_Doc file ******

-- S8.
-- How can you use user activity data to identify potential brand ambassadors
-- or advocates who could help promote Instagram's initiatives or events?

WITH top_users AS (
    
    SELECT id, username
    FROM users
    WHERE id IN (
        SELECT followee_id 
        FROM follows 
        GROUP BY followee_id 
        HAVING COUNT(*) = (
            SELECT COUNT(*) FROM follows GROUP BY followee_id ORDER BY 1 DESC LIMIT 1
        )
    )
),
stats AS (
    
    SELECT 
        p.user_id,
        (SELECT COUNT(*) FROM likes l WHERE l.photo_id IN (SELECT id FROM photos WHERE user_id = p.user_id)) as total_likes,
        (SELECT COUNT(*) FROM comments c WHERE c.photo_id IN (SELECT id FROM photos WHERE user_id = p.user_id)) as total_comments
    FROM photos p
    WHERE p.user_id IN (SELECT id FROM top_users)
    GROUP BY p.user_id
)
SELECT 
    u.id AS user_id,
    u.username,
    (SELECT COUNT(*) FROM follows WHERE followee_id = u.id) AS follower_count,
    (COALESCE(s.total_likes, 0) + COALESCE(s.total_comments, 0)) AS total_engagement
FROM top_users u
LEFT JOIN stats s ON u.id = s.user_id
ORDER BY total_engagement DESC
LIMIT 4;

-- S9.
-- How would you approach this problem, if the objective and subjective
-- questions weren't given?

-- ****** Answered in the Project_Doc file ******

-- S10.
-- Assuming there's a "User_Interactions" table tracking user engagements, how
-- can you update the "Engagement_Type" column to change all instances of
-- "Like" to "Heart" to align with Instagram's terminology?

DROP TABLE IF EXISTS User_Interactions;

CREATE TABLE User_Interactions(
	id INT AUTO_INCREMENT UNIQUE PRIMARY KEY,
	username VARCHAR(250) NOT NULL,
	Engagement_Type varchar(250) not null
);

INSERT INTO User_Interactions (username,Engagement_Type ) VALUES 
('Kenton_Kirlin', 'Like'),
 ('Andre_Purdy85', 'Comments'), 
 ('Harley_Lind18', 'Comments'),
 ('Arely_Bogan63', 'Comments'), 
 ('Aniya_Hackett', 'Like'), 
 ('Travon.Waters', 'Like'), 
 ('Kasandra_Homenick', 'Comments'), 
 ('Tabitha_Schamberger11', 'Comments'),
 ('Gus93', 'Like'), 
 ('Presley_McClure', 'Comments'), 
 ('Justina.Gaylord27', 'Like'), 
 ('Dereck65', 'Comments'), 
 ('Alexandro35', 'Comments'), 
 ('Jaclyn81', 'Comments'), 
 ('Billy52', 'Like'), 
 ('Annalise.McKenzie16', 'Comments'), 
 ('Norbert_Carroll35', 'Like'), 
 ('Odessa2', 'Comments'), 
 ('Hailee26', 'Comments'), 
 ('Delpha.Kihn', 'Like'), 
 ('Rocio33', 'Like'), 
 ('Kenneth64', 'Like'), 
 ('Eveline95', 'Like'),
 ('Maxwell.Halvorson', 'Like'), 
 ('Tierra.Trantow', 'Like'),
 ('Josianne.Friesen', 'Like'), 
 ('Darwin29', 'Like'), 
 ('Dario77', 'Like'),
 ('Jaime53', 'Comments'),
 ('Kaley9', 'Comments'), 
 ('Aiyana_Hoeger', 'Like'), 
 ('Irwin.Larson', 'Like'), 
 ('Yvette.Gottlieb91', 'Comments'), 
 ('Pearl7', 'Like'), 
 ('Lennie_Hartmann40', 'Comments'), 
 ('Ollie_Ledner37', 'Like'), 
 ('Yazmin_Mills95', 'Comments'), 
 ('Jordyn.Jacobson2', 'Like'), 
 ('Kelsi26', 'Like'), 
 ('Rafael.Hickle2', 'Comments'), 
 ('Mckenna17', 'Like'), 
 ('Maya.Farrell', 'Comments'), 
 ('Janet.Armstrong', 'Like'), 
 ('Seth46', 'Comments'), 
 ('David.Osinski47', 'Like'), 
 ('Malinda_Streich', 'Comments'), 
 ('Harrison.Beatty50', 'Like'), 
 ('Granville_Kutch', 'Comments'), 
 ('Morgan.Kassulke', 'Like'), 
 ('Gerard79', 'Comments'), 
 ('Mariano_Koch3', 'Comments'), 
 ('Zack_Kemmer93', 'Like'), 
 ('Linnea59', 'Comments'), 
 ('Duane60', 'Comments'), 
 ('Meggie_Doyle', 'Like'), 
 ('Peter.Stehr0', 'Comments'), 
 ('Julien_Schmidt', 'Like'), 
 ('Aurelie71', 'Comments'), 
 ('Cesar93', 'Comments'), 
 ('Sam52', 'Like'), 
 ('Jayson65', 'Comments'), 
 ('Ressie_Stanton46', 'Like'), 
 ('Elenor88', 'Comments'), 
 ('Florence99', 'Like'), 
 ('Adelle96', 'Comments'), 
 ('Mike.Auer39', 'Comments'), 
 ('Emilio_Bernier52', 'Like'), 
 ('Franco_Keebler64', 'Comments'), 
 ('Karley_Bosco', 'Like'), 
 ('Erick5', 'Comments'), 
 ('Nia_Haag', 'Like'), 
 ('Kathryn80', 'Comments'), 
 ('Jaylan.Lakin', 'Like'), 
 ('Hulda.Macejkovic', 'Comments'), 
 ('Leslie67', 'Comments'), 
 ('Janelle.Nikolaus81', 'Like'), 
 ('Donald.Fritsch', 'Comments'), 
 ('Colten.Harris76', 'Like'), 
 ('Katarina.Dibbert', 'Comments'), 
 ('Darby_Herzog', 'Comments'), 
 ('Esther.Zulauf61', 'Like'), 
 ('Aracely.Johnston98', 'Comments'), 
 ('Bartholome.Bernhard', 'Comments'), 
 ('Alysa22', 'Comments'), 
 ('Milford_Gleichner42', 'Like'), 
 ('Delfina_VonRueden68', 'Comments'), 
 ('Rick29', 'Like'), 
 ('Clint27', 'Comments'), 
 ('Jessyca_West', 'Comments'), 
 ('Esmeralda.Mraz57', 'Like'), 
 ('Bethany20', 'Comments'), 
 ('Frederik_Rice', 'Comments'), 
 ('Willie_Leuschke', 'Like'), 
 ('Damon35', 'Comments'), 
 ('Nicole71', 'Comments'), 
 ('Keenan.Schamberger60', 'Like'), 
 ('Tomas.Beatty93', 'Comments'), 
 ('Imani_Nicolas17', 'Like'), 
 ('Alek_Watsica', 'Comments'), 
 ('Javonte83', 'Like');
 
 SET SQL_SAFE_UPDATES = 0;
 update  User_Interactions 
 set  Engagement_Type = "Heart" 
 where Engagement_Type= "Like";
 
select * from User_Interactions; 

/* ===================================== END OF FILE ===================================== */
