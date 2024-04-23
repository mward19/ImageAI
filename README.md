## TODO:
- FSL Groups (Braxton is an group manager so he can add as well as Gus)
- Quartz(along with X11 forwarding: denoted by -X option for ssh) for using GUI on Super Computer
- Access super computer via vscode (consider .ssh/config option for setting up alias and multiplexing i.e. ssh sc)
# ImageAI Walkthru

1. Github: Understand the full [quickstart section](https://docs.github.com/en/get-started)
2. Setup an account on and download Zulip. We will use this to communicate within our group.
    * https://zulip.com
    * Ask any group member to send you an invitation to our Zulip organization
3.  Get an account on the supercomputer
    * Go to https://rc.byu.edu
    * Click on "Request an account" in the top right corner
    * Follow the prompts to send your request, you will need to
      login with your byu email and provide some information about our project
    * 
          - Professor Hart's id is glh43. When asked for info about your project,
            just say that you are working on an imageAI biophysics project sorting
            pictures of the flagellar motor.You will be doing machine learning and
            will be using PyTorch. One job at a time requesting up to 16GB on a GPU.
    * After about a day you should receive an email on your byu email saying that your request has been approved or denied.
      * If it is denied: ->let us know in the ImageAI channel on Zulip. Give the reasoning why.
      * If it is approved: ->You are ready to proceed and access the Supercomputer!
    * Download Google Authenticator
<<<<<<< HEAD
    * Return to https://rc.byu.edu and login. Set up two factor authentication using the QR code on the website.
=======
    * Return to https://rc.byu.edu and click 'Log In' at the top of the page and log in with your username and password. Set up two factor authentication using Google Authenticator and the QR code on the website.
>>>>>>> f13e1b3 (Updated two factor authentication instructions for supercomputer)
    * If using Mac (GOOD JOB!) open terminal and type  "ssh *username*@ssh.rc.byu.edu" replacing *username* with yours
    * You will then be prompted to enter your password you made on the rc.byu website followed by your 6-digit google authenticator code
    * You will not immediately have access to the group's shared files and directories.
    * Begin following the tutorials under the documentation section of the rc website. (Most of the YT vids are out of date but there are a few seminars from 2020 you can look at. Mainly just focus on '**Linux tutorial**'. This will teach you how to navigate the supercomputer.)
    * Once you feel comfortable with the LinuxOS let us know and we will give you access to our shared group directory.
    * Linux Cheat Sheet: https://docs.google.com/document/d/1rwuWKhjxmHehSVlJTS4vgwJxQZZZxg5z0vF_GyNLXE0/edit?usp=sharing
4.  Get Julia installed
    * Go to https://julialang.org/downloads/
    * If using Mac, be sure to check which processor/chip your computer has. (APPLE LOGO, About this Mac)
        * If it says "Chip" anywhere, be sure to download the Apple Silicon .dmg file.
        * If it says "Processor" anwhere, be sure to download the Intel .dmg .
    * Follow the instructions to get Julia up and running!
5.  Install VScode
    * VScode is great, however, any ide or text editor will work. If you are feeling brave try [vim](https://www.vim.org/)
    * Go to https://code.visualstudio.com/download
    * Be sure to follow the same rules about the chip/processor
    * Install the Julia extension
      * Open VScode and press command[⌘], shift[⇧], [X]
      * Search Julia and install the 'Julia Language Support' extension
    * You are now ready to use Julia in VScode!   

6.  Do Chapters 1, 2, and 9 of [Giordano](https://drive.google.com/drive/folders/1fRZ3O7edJSBFz9f5hYGVnzf6_JLeRBmc?usp=sharing) and pass it off
