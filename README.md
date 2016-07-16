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

##### Data Size
- The size of data in a deep network can be one, two, three, or four dimensional.  The Convolution program uses image data, so most data is presented as a two-dimensional array, or a 1-dimensional result vector from a network layer.  A size is defined with the number of dimensions and the size of each dimension.  Unused dimensions are often given as having a size of 1.


##  Network Operators
#### Convolution2D
##### Network Operator Table Information
A Convolution2D operator appears in the Network Operator table with a type of "2D Convolution" and details giving the convolution matrix type and the values of the matrix in a single-dimensional array.

#### Pooling
##### Network Operator Table Information
A Pooling operator appears in the Network Operator table with a type of "Pooling" and details giving the pooling type (average, minimum, or maximum), and the reduction factor for each dimension.

#### FeedForwardNN
##### Network Operator Table Information
A Neural Network operator appears in the Network Operator table with a type of "FeedForward NN" and details giving the activation function for the network and the resulting data size (based on the number of nodes in the network).


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

#### Inputs
##### Input List
- The input list shows all the defined inputs for the deep network.  Each input set is has a tag name for reference by the first layer's channels, and an input data type.  See the section on the Input Sheet for a list of data types.

##### Add Button
- The 'Add' button underneath the input list activates the Input Sheet for defining a new input set.  See the section on the Input Sheet for use of this sheet.  The order of inputs in the list does not matter.

##### Delete Button
- The 'Delete' button underneath the input list removes the input set that is currently selected from the deep network.

#### Layers
##### Layer List
- The layer list shows all the defined layers for the deep network.  Each layer is shown with an index reference (showing the order the layers are processed), and the number of defined channels in that layer.  Selecting a layer in the list fills the channel list with the channels from the selected layer, and enables modification of the defined channels for the layer.

##### Add Button
- The 'Add' button underneath the layer list adds a new layer to the end of the layer list.  The layer is added with no defined channels.  The order of layers in the list is used as the processing order.

##### Delete Button
- The 'Delete' button underneath the layer list removes the layer that is currently selected from the deep network, including all defined channels in that layer.

#### Channels
##### Channel List
- The channel list shows all the defined channels for the selected layer of the deep network.  Each channel is shown with a the identifier tag for the channel, the input tag used to get data from the previous layer (or the input sets if this channel is in the first layer), and the size of data output from the channel.  Selecting a channel in the list fills the network operator list with the operators from the selected channel, and enables modification of the defined operators for the channel.

##### Add Button
- The 'Add' button underneath the channel list activates the Channel Sheet for defining a new channel for the selected layer.  See the section on the Channel Sheet for use of this sheet.  The order of channels in the list does not matter.

##### Delete Button
- The 'Delete' button underneath the channel list removes the channel that is currently selected from the layer, including all defined operators in that channel.

#### Network Operators
##### Operator List
- The operator list shows all the defined operators for the selected channel of the selected layer of the deep network.  Each operator is shown with the type of operator and a detail string.  For more information on operators, see the Network Operators section of this manual.  Selecting an operator in the list may affect the image shown in the data image section (see that section for more information).

##### Add Button
- The 'Add' button underneath the operator list activates the appropriate sheet for defining a new operator for the selected channel.  The type of sheet opened is set by the operator type selection to the right of the Add button.  See the section for the approprate sheed for use information.  The order of operators in the list determines the order that the operations are performed when the channel is processed.

##### Operator Type Selection
- This drop-down list contains all of the currently defined operators that can be added to a channel in a deep network.  See the Network Operators section of this manual for information on the currently known types.

##### Edit Button
- The 'Edit' button underneath the operator list is not currently functional.

##### Delete Button
- The 'Delete' button underneath the operator list removes the operator that is currently selected from the channel.


##  Input Sheet
The input sheet is used to add or modify an input set definition.  The following sections describe the entries in the sheet
#### Identifier
- This text entry field takes the string identifier for the input set.  This string is used by channels to reference the data.  The identifier is case sensitive.  Other than being unique, there are no restrictions on the string.

#### Data Type
- This drop-down selection list is used to choose the type of image data that the input set will provide.  Each data type only needs to be referenced once, and then only if needed.  The following list defines the image data types:
    * Red Channel - the red value of each pixel, scaled to a floating value between 0.0 and 1.0
    * Green Channel - the green value of each pixel, scaled to a floating value between 0.0 and 1.0
    * Blue Channel - the blue value of each pixel, scaled to a floating value between 0.0 and 1.0
    * Average Intensity - the average of the red, green, and blue channels of each pixel, scaled to a floating value between 0.0 and 1.0
    * Average Minimum - the minimum of the red, green, and blue channels of each pixel, scaled to a floating value between 0.0 and 1.0
    * Average Maximum - the maximum of the red, green, and blue channels of each pixel, scaled to a floating value between 0.0 and 1.0


##  Channel Sheet
The channel sheet is used to add or modify an channel definition.  The following sections describe the entries in the sheet
#### Channel Identifier
- This text entry field takes the string identifier for the channel.  This string is used by channels in subsequent layers to reference the output from this channel.  The identifier is case sensitive.  Other than being unique, there are no restrictions on the string.

#### Input Source ID
- This text entry field takes the string identifier for the input source from the previous layer, which is either a channel identifier for the channel in that layer, or an input set if the current channel is in the first layer.  The ID must match an input source for the network to be considered valid.


##  Experiments
1. Horizontal lines - learns to discriminate between horizontal and vertical lines
    - File->Open the Test1_Horizontal file.  This is a simple network with one channel.  A convolution of horizontal gradient, pooling down to 16 squares using maximum, and a single node neural net
    - Select the HorizontalTest file from the HorizontalTest directory for testing
    - Leave repeat training and Auto testing on.
    - Click 'Train'
    - The network should fairly quickly learn the horizontal lines, getting a 100% test rate in under a minute.
    



## License

This program is made available with the [Apache license](LICENSE.md).
