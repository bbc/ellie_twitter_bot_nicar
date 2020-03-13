pacman::p_load('tidyverse', 'magick', 'ggimage')

setwd("~/Desktop/ellie_twitter_bot_nicar/")

# This script is for creating constituency results cards for twitter

# This is the path to the csv of data that you want to feature in the card.
data_csv = './fixtures/UC0001MAC.csv'

# This is where you want to save your new card
filepath_dir = './'

#  This is the path for the background card
backing_path = './src/R/background.png'



#----Formatting your data----

# STEP 1. arrange and filter

result_df <- read.csv(data_csv) %>%
  # puts results in the correct order
  arrange(constituency_shortName, desc(votesNow)) %>%
  # gives each row an order number
  mutate(order = seq(1, length(party_shortName), 1)) %>%
  # Takes the top six candidates
  filter(order < 7)

# STEP 2. add in your colours

result_df <- result_df %>%
  mutate(
    # colours for candidates
    colour = case_when(
      candidate_party_code == 'MAC' ~ '#AD08F9',
      candidate_party_code == 'SA' ~ '#023022',
      candidate_party_code == 'MRP' ~ '#5B0101',
      candidate_party_code == 'ECA' ~ '#588300',
      candidate_party_code == 'TPM' ~ '#FFA31E',
      candidate_party_code == 'IND' ~ '#1380A1',
      TRUE ~ "#BABABA"
    ),
    # colours for winning party
    colour2019 = case_when(
      newPartyCode == 'MAC' ~ '#AD08F9',
      newPartyCode == 'SA' ~ '#023022',
      newPartyCode == 'MRP' ~ '#5B0101',
      newPartyCode == 'ECA' ~ '#588300',
      TRUE ~ "#BABABA"
      ),
    # colours for previous party
    colour2017 = case_when(
      partyCodeLast == 'MAC' ~ '#AD08F9',
      partyCodeLast == 'SA' ~ '#023022',
      partyCodeLast == 'MRP' ~ '#5B0101',
      partyCodeLast == 'ECA' ~ '#588300'
    )
  )

# STEP 3. make our text more readable

result_df <- result_df %>%
    # puts short result into x form and into the correct case
  mutate(
    result = resultBanner,
    result = gsub('WIN', 'win seat', result),
    result = gsub('HOLD', 'hold seat', result),
    result = gsub('GAIN FROM', 'gain seat from', result),
    result = gsub('MAC', 'Modern Alliance', result),
    result = gsub('SA', 'Social Advancement', result),
    result = gsub('MRP', 'Moderate Resistance', result),
    result = gsub('ECA', 'Environmental Climate Alliance', result)
  )


#----Creating coordinates data frame----


cand_box_height = 20 # the height of each candidate row in the card

cand_gap_height = 9 # the gap between the rows

scoreboard_box_df <-
  # The coloured party indicators at the beginning of each row
  tibble(
    order = rep(6:1, each = 4),
         group = rep(
           c('cand6', 'cand5', 'cand4', 'cand3', 'cand2', 'cand1'),
           each = 4
         ),
    # width of the solid colour bar
    x_small = rep(c(3,
                  6,
                  6,
                  3), times = 6),
    # width of the opaque colour box
    x_large = rep(c(6,
                  57,
                  57,
                  6), times = 6),
    # height of both bar and box
    y = rep(c(cand_box_height,
                cand_box_height,
                0,
                0), times = 6),
    # this creates the coordinates for all the bars
    # the maximum number of rows here is 6.
    grow = rep(
      seq(
        from = 0,
        to = (cand_box_height + cand_gap_height) * 5,
        by = cand_box_height + cand_gap_height
      ),
      each = 4
    )
  ) %>%
  mutate(y = y + grow) %>%
  left_join(result_df, by = 'order') %>%
  filter(!is.na(constituency_shortName))




#----Building the sections  of the plot----

#----Section 1. Fixed text - three elements----
twitter_card <- ggplot() +
  # set the size of your card
  scale_y_continuous(limits = c(-46, 263.375), expand = c(0, 0)) +
  scale_x_continuous(limits = c(0, 550), expand = c(0, 0)) +
  #----Section 1. Fixed text - four elements----
# Constituency name
geom_text(
  aes(
    x = 2,
    y = 243,
    label = scoreboard_box_df$constituency_shortName[1]
  ),
  hjust = 0,
  vjust = 0.5,
  size = 64,
  colour = '#3f3f42',
  family = "Georgia"
) +
  # Current election year
  geom_text(
    aes(x = 2, y = 183, label = "2020"),
    hjust = 0,
    vjust = 0.5,
    size = 40,
    colour = '#6E6E73',
    family = "Helvetica"
  ) +
  # previous election year
  geom_text(
    aes(x = 380, y = 183, label = "2016"),
    hjust = 1,
    vjust = 0.5,
    size = 40,
    colour = '#6E6E73',
    family = "Helvetica"
  )

ggplot2::ggsave(twitter_card,
                filename = paste0(filepath_dir = filepath_dir, '/temp.png'),
                width = (1920 / 72 * 2),
                height = (1080 / 72 * 2),
                bg = "white",
                limitsize = FALSE
)


#----Section 2. Winning party polygons - two elements----

# current election year polygon
twitter_card <- twitter_card +
geom_polygon(aes(y = c(202, 202, 193, 193),
                 x = c(3, 328, 322, 3)),
             fill = scoreboard_box_df$colour2019[1])  +
  # previous election year polygon
  geom_polygon(aes(
    y = c(202, 202, 193, 193),
    x = c(330, 380, 380, 324)
  ),
  fill = scoreboard_box_df$colour2017[1])

ggplot2::ggsave(twitter_card,
                filename = paste0(filepath_dir = filepath_dir, '/temp.png'),
                width = (1920 / 72 * 2),
                height = (1080 / 72 * 2),
                bg = "white",
                limitsize = FALSE
)

  #----Section 3. candidate_picture/logo - one element ----

# This is the  path to the photo of the winning candidate. It creates the path by pasting together different elements:
# the second argument ie the filepath of the folder containing the photos, the unique code for the constituency, the winning party
# `result_df$newPartyCode[1]` and finally the file type.
candidate_picture <- paste0(filepath_dir, 'fixtures/UC0001_', result_df$newPartyCode[1], ".png")
print(candidate_picture)

twitter_card <-
  twitter_card +
  ggimage::geom_image(aes(x = 470, y = 100, image = candidate_picture),
                      size = 0.29,
                      asp = 1.85)

ggplot2::ggsave(twitter_card,
                filename = paste0(filepath_dir = filepath_dir, '/temp.png'),
                width = (1920 / 72 * 2),
                height = (1080 / 72 * 2),
                bg = "white",
                limitsize = FALSE
)

  #----Section 4. Candidate party colours - two elements----
 # large polygon
twitter_card <-
  twitter_card +
  scale_fill_identity() +
 geom_polygon(
    data = scoreboard_box_df,
    aes(
      x = x_large,
      y = y,
      group = group,
      fill = colour
    ),
    colour = NA,
    alpha = 0.1
  ) +
  # small polygon
  geom_polygon(
    data = scoreboard_box_df,
    aes(
      x = x_small,
      y = y,
      group = group,
      fill = colour
    ),
    colour = NA,
    alpha = 1
  )

ggplot2::ggsave(twitter_card,
                filename = paste0(filepath_dir = filepath_dir, '/temp.png'),
                width = (1920 / 72 * 2),
                height = (1080 / 72 * 2),
                bg = "white",
                limitsize = FALSE
)

#---- Section 5. Dynamic text - five elements ----

twitter_card <-
  twitter_card +
  # Result banner
  geom_text(
    aes(
      x = 2,
      y = 214,
      label = scoreboard_box_df$result[1]
    ),
    hjust = 0,
    vjust = 0.5,
    size = 40,
    colour = '#6E6E73',
    family = "Helvetica"
  )  +
  # candidate name
geom_text(
  aes(
    x = 64,
    # the y value is calculated using the cand_box_height defined on line 80 and cand_gap_height defined on line 82
    # multiply by 6 becuase this is the max number of candidates and then minus the cand_box_height + cand_gap_height 
    # multiplied by the order number of the candidate. This is then added top the height of the box divided by 2 to 
    # get the mid point of the box because you want teh text to sit in the middle of the box. 
    y = ((cand_box_height + cand_gap_height) * 6 - ((cand_box_height + cand_gap_height) * scoreboard_box_df$order
    ) + cand_box_height / 2
    ),
    label = scoreboard_box_df$fullName
  ),
  hjust = 0,
  size = 40,
  colour = '#3f3f42',
  family = "Helvetica"
) +
  # candidate party
  geom_text(
    aes(
      x = 8,
      y = ((cand_box_height + cand_gap_height) * 6 - ((cand_box_height + cand_gap_height) * scoreboard_box_df$order
      ) + cand_box_height / 2
      ),
      label = scoreboard_box_df$candidate_party_code
    ),
    hjust = 0,
    size = 40,
    colour = '#3f3f42',
    family = "Helvetica"
  ) +
  # candidate votes
  geom_text(
    aes(
      x = 380,
      y = ((cand_box_height + cand_gap_height) * 6 - ((cand_box_height + cand_gap_height) * scoreboard_box_df$order
      ) + cand_box_height / 2

      ),
      label = prettyNum(scoreboard_box_df$votesNow, big.mark = ",")
    ),
    hjust = 1,
    size = 40,
    colour = '#3f3f42',
    family = "Helvetica"
  ) +
  # Majority
  geom_text(
    aes(
      x = 380,
      y = min(scoreboard_box_df$y) - 25,
      label = paste(
        "Majority:",
        prettyNum(scoreboard_box_df$majorityNow[1], big.mark = ",")
      )
    ),
    hjust = 1,
    size = 40,
    colour = '#3f3f42',
    family = "Helvetica",
    fontface = 'bold'
  ) +
  # Turnout
  geom_text(
    aes(
      x = 64,
      y = min(scoreboard_box_df$y) - 25,
      label = paste0(
        "Turnout: ",
        round(scoreboard_box_df$turnout_percentage[1], 1),
        "%"
      )
    ),
    hjust = 0,
    size = 40,
    colour = '#3f3f42',
    family = "Helvetica",
    fontface = 'bold'
  )



ggplot2::ggsave(twitter_card,
                filename = paste0(filepath_dir = filepath_dir, '/temp.png'),
                width = (1920 / 72 * 2),
                height = (1080 / 72 * 2),
                bg = "white",
                limitsize = FALSE
)

#---- Finalise styling ----
twitter_card <-
  twitter_card +
  theme(
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_blank(),
    panel.background = ggplot2::element_blank(),
    legend.position = 'none'
  ) +
  coord_fixed()



ggplot2::ggsave(twitter_card,
  filename = paste0(filepath_dir = filepath_dir, '/temp.png'),
  width = (1920 / 72 * 2),
  height = (1080 / 72 * 2),
  bg = "white",
  limitsize = FALSE
)


#----ADDING THE BACKGROUND----
# this uses the 'magick' package to combine the bcakground and the twitter card

# 1. read in the backing
backing <- magick::image_read(backing_path)



# 2. read in the chart and convert the white to transparent so you will be able to see the background
# when they are combined
chart <- magick::image_read(paste0(filepath_dir = filepath_dir, '/temp.png')) %>%
  magick::image_transparent("white")

# resize the chart do it has the same dimensions as the backing
chart_scale <-
  magick::image_scale(
    chart, "1920x1080"

  )


# Put the backing and the twitter card together.
composite <- magick::image_composite(backing,
                                     chart_scale,
                                     offset = "+0+0")

# writes out the composite
magick::image_write(composite, path = paste0(filepath_dir = filepath_dir, 'graphic.png'), "png")

