url = "https://i.imgur.com/VGPeJ6s.jpg"

download(url, "philip.jpg")

#remove semi-colon to see images

using Images, ImageView, ImageSegmentation
philip = load("philip.jpg") #original picture of philip

#lets identify some things to segment
philip[600:700,1:400] #range of possible pixles from towel seed
philip[1100:1200,1:500] #range of possible pixles from rug seed 
philip[2000:2500,1:500] #range of possible pixles from wood floor
philip[1200:1600,2500:2800] #range of possible pixles from wall
philip[200:500,500:1600]  #range of possible pixles from shadows


#choosing random value from range
towel = (CartesianIndex(632,255),1)
rug = (CartesianIndex(1125,322),2)
floor = (CartesianIndex(2222,333),3)
wall = (CartesianIndex(1400,2600),4)
shadow = (CartesianIndex(300,1000),5)

seeds = [towel, rug, floor, wall, shadow]

segments = seeded_region_growing(philip, seeds)

imshow(philip)
imshow(map(i->segment_mean(segments,i), labels_map(segments)));

