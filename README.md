# Smart git

This application visualizes a repository and displays commit messages with it. The data is extracted from github through their API. Since they do not provide an easy endpoint to build up a tree, all the data crunching has been carried out on the backend. This also mimics the real life scenario, since we do not want to make a bunch of request on the user's phone just to make a tree. 

![](demo1.gif) ![](demo2.gif)
## How does it work?

Type in a github repository name in the following way:
```
owner/name
```
So in the case of a repository called '*demonstration*' which belongs to the user '*justfor*' it would be:
```
justfor/demonstration
```
Tap the search icon to see the results. 

## Results
- Invalid input - This happens when you forgot the slash
- Something went wrong
  - This can happen to many reasons. 
    - Too large repository
    - Non existing repository
    - Internet connection problems
- Displays the tree with the commits.

## Data format
To be able to reproduce these visualizations, I provide the format the backend sends to visualize the tree. 
```json
[
  {
    "x": "x position of the commit in the grid",
    "message": "commit message",
    "color": "color of the commit",
    "routes": [
      {
        "from": "The beginning of a route on this level of the tree",
        "to": "The end of a route on this level of the tree",
        "color": "The color of the current route"
      }
      ...
    ]
  }
  ...
]
```
The order of the array is important, as it contains the commits in order, from the bottom to the top.

### Remarks
I was only able to test it on android. 