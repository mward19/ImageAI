import os
import shutil
from tkinter import Tk, Label, Button, PhotoImage
from PIL import Image, ImageTk

# Path to the directories
source_directory = '../allimgs'
destination_directory = 'my_selected_images'

# Make sure the destination directory exists
if not os.path.exists(destination_directory):
    os.makedirs(destination_directory)

# List all files in the source directory
images = [file for file in os.listdir(source_directory) if file.endswith(('png', 'jpg', 'jpeg', 'gif'))]
current_image_index = 0

def show_next_image(advance=True):
    global current_image_index
    if advance:
        current_image_index += 1
    if current_image_index >= len(images):
        print("Finished processing all images.")
        root.quit()  # Quit the application when the last image is reached
        return
    image_path = os.path.join(source_directory, images[current_image_index])
    load_image(image_path)

def copy_image():
    source_path = os.path.join(source_directory, images[current_image_index])
    destination_path = os.path.join(destination_directory, images[current_image_index])
    shutil.copy2(source_path, destination_path)
    print(f"Copied: {images[current_image_index]}")
    show_next_image()

def load_image(image_path):
    img = Image.open(image_path)
    img = img.resize((500, 500), Image.ANTIALIAS)  # Resize the image, if necessary
    img = ImageTk.PhotoImage(img)
    image_label.configure(image=img)
    image_label.image = img

def on_key(event):
    if event.keysym.lower() == 'p':
        copy_image()
    elif event.keysym.lower() == 'q':
        show_next_image()

# Set up the GUI
root = Tk()
root.title('Image Viewer')

image_label = Label(root)
image_label.pack()

# Buttons for actions
next_button = Button(root, text="Next Image (Press 'q')", command=lambda: show_next_image())
next_button.pack(side='left', padx=10, pady=10)

copy_button = Button(root, text="Copy Image (Press 'p')", command=copy_image)
copy_button.pack(side='right', padx=10, pady=10)

# Bind key events to the root window for keyboard shortcuts
root.bind('<Key>', on_key)

# Display the first image
show_next_image(advance=False)

root.mainloop()
