# Convolution
A Mac GUI for the deep-network convolution routines in AIToolbox

This is an interface to attempt to learn classification labels for images using the DeepNetwork class that will shortly be added to the AIToolbox framework

I will add some instructions on how to use it here over the next few days

Still a few missing options, but it learns the first batch - recognizing horizontal line images!


##  Concepts
##### DeepNetwork
- A network consisting of one or more layers that operate on ordered data.  A DeepNetwork requires a list of tagged inputs, and a set of layers.  Each feedforward pass of the network requires the inputs to be inserted into the network, after which the network will iterate through the defined layers sequentially, performing the operations defined within them.
- The output of a deep network is a single integer that gives the class label for the best estimate of the image classification.  The number of image classes possible is a function of the number of outputs of the the last channel of the last layer.  One output value can give two classes (class 0 and 1), more than one output gives a possible class for each of the outputs (i.e. a 5 value output from the last layer can indicate 5 different image classes).

##### Layer
- A single layer of the deep network.  Each layer is processed sequentially, as the inputs from the previous layer must be available to feed into the next layer.  Each layer can only reference the outputs from the previous layer (or the initial inputs by the first layer).
- A layer contains one or more channels.  All channel are processed concurrently, speeding up operation of the network.

##### Channel
- A set of operations that can be performed individually.  A channel is tagged, so that it's output can be referenced by channels in the next layer.  A channel has a source tag, defining the source of input data from the previous layer (or the network input set if the channel is in the first layer).
- A channel contains one or more NetworkOperators.  These are individual operations on the data.  Operators include convolutions, poolings, and feedforward neural networks.  The operators are performed sequentially in the channel, with the first operator getting the inputs from the previous layer, the next operator getting the outputs of the first operator as inputs, etc., until the output of the last operator is tagged with the channel tag for reference by any channels in the next layer.

##### Labelled Image
- An image that has an integer class label assigned to it.  Labels for a data set should start at 0 and be sequential

##### Batch
- A set of training runs that result in one update of the weight parameters in the network.  The weight changes are cleared at the beginning of a batch, accumulated during the batch, and the weights updated with the accumulations at the end of the batch.

##### Epoch
- A set of training runs consisting of a single batch training set for each epoch.  Training can be set up to be forever (stopped only by the user), or proceed for a specified number of epochs before automatically stopping.

##  Menu commands
##### Convolution->Quit
- Closes the application.  It will NOT ask to save work, even if something was modified.

##### File->Open
- Loads a network model, training parameters, and input definitions from a previously saved file.  Testing image sets identifiers are not saved or loaded.

##### File->Save
- Saves a network model, training parameters, and input definitions to a file.  The file is a standard plist file (a subset of XML), so it can be examined and possibly modified.

##  Main Window
#### Scale Image to Size
- This selection list specifies the pixel size and width that both training and testing images will be scaled to before being used by the DeepNetwork class.  Valid sizes are square with each side a power of two between 4 and 256 pixels.

#### Training Image source
- Currently this section is not operable.  All training images are randomly generated images of red lines, labelled with class 1 for horizontal lines, and class 0 for vertical lines.

#### Training
##### Train Button
- This button will start the training (assuming a valid network has been specified).  While training is in progress, the button will change to 'Stop'.  Clicking on the button again will stop the training at the end of processing the current image.  While waiting for the current image to finish, the button will sat 'Stopping'.  Note that network weights are only updated at the end of a batch, so stopping in the middle of a batch will lose any weight changes from already processed images.

##### Repeat Forever Checkbox
- The checkbox with the circle arrow ('⟲') will determine if the training is repeated until manually stopped, or will stop automatically after the specified number of epochs has been processed.  If checked, training is done until manually stopped.

##### Batch Size Entry
- This numeric entry field with a 'spinner' is used to specify the number of training images that are processed between weight updates.  The number must be at least 1.

##### Number of Epochs Entry
- This numeric entry field with a 'spinner' is used to specify the number of epochs to train before stopping - assuming the 'Repeate Forever' checkbox is not selected.  The number must be at least 1.

##### Training Rate Entry
- This numeric entry field is used to specify the multiplier used on the accumulated error derivitives with respect to each weight, before it is added to the weights at the end of the batch.  The number must be between 0.0001 and 100.0.

##### Weight Decay Entry
- This numeric entry field is used to specify the multiplier used on the each weight, before the weight change accumulations are added to the weights at the end of the batch.  The number must be between 0.00001 and 1.0.  This is used for weight decay, a type of simple regularization.  A typical value is something like 0.9998, a 0.02% drop in the weights each batch update.


##  Experiments
1. Horizontal lines - learns to discriminate between horizontal and vertical lines
    - File->Open the Test1_Horizontal file.  This is a simple network with one channel.  A convolution of horizontal gradient, pooling down to 16 squares using maximum, and a single node neural net
    - Select the HorizontalTest file from the HorizontalTest directory for testing
    - Leave repeat training and Auto testing on.
    - Click 'Train'
    - The network should fairly quickly learn the horizontal lines, getting a 100% test rate in under a minute.
    



## License

This program is made available with the [Apache license](LICENSE.md).
