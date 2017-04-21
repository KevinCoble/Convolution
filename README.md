# Convolution
A Mac GUI for the deep-network convolution routines in AIToolbox

This is an interface to attempt to learn classification labels for images using the DeepNetwork class that has been added to the AIToolbox framework.

**Make sure you have the latest AIToolbox framework installed!**

I will add some instructions on how to use it here over the next few days.  For now, look at the example experiments at the end of this document.

Still a few missing options, but it learns the first and second batches - recognizing horizontal line images and differentiating circles from lines!


##  Concepts
##### DeepNetwork
- A network consisting of one or more layers that operate on ordered data.  A DeepNetwork requires a list of tagged inputs, and a set of layers.  Each feedforward pass of the network requires the inputs to be inserted into the network, after which the network will iterate through the defined layers sequentially, performing the operations defined within them.
- The output of a deep network is a single integer that gives the class label for the best estimate of the image classification.  The number of image classes possible is a function of the number of outputs of the the last channel of the last layer.  One output value can give two classes (class 0 and 1), more than one output gives a possible class for each of the outputs (i.e. a 5 value output from the last layer can indicate 5 different image classes).

##### Layer
- A single layer of the deep network.  Each layer is processed sequentially, as the inputs from the previous layer must be available to feed into the next layer.  Each layer can only reference the outputs from the previous layer (or the initial inputs by the first layer).
- A layer contains one or more channels.  All channel are processed concurrently, speeding up operation of the network.  The last layer should only have one channel, as it should be providing the output for the deep network.

##### Channel
- A set of operations that can be performed individually.  A channel is tagged, so that it's output can be referenced by channels in the next layer.  A channel has a set of source tags, defining the sources of input data from the previous layer (or the network input set if the channel is in the first layer).  Multiple sources must be of a size that can be 'stacked' together to create a single data set that is fed into the first operator of the channel.  For example, two 16x16 inputs can be stacked into a 16x16x2 input set.  A 32x32 can stack onto a 32x32x4 input to get a 32x32x5 input set.
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
##### Operation Definition
A Convolution2D operator requires a two-dimensional data array as input.  The operator processes each image pixel by multiplying each pixel value of the input data, and its' neighboring values by a small 2-dimensional matrix and summing the results.  For example, a 3x3 matrix convolution will multiply the pixel value by the center value of the convolution matrix, add the image value to the upper-left of the target pixel multiplied by the upper-left convolution matrix value, add the image value above the target pixel multiplied by the top-center matrix value, etc.  The resulting data is a 2-dimensional array of the same size as the image data.

##### Network Operator Table Information
A Convolution2D operator appears in the Network Operator table with a type of "2D Convolution" and details giving the convolution matrix type and the values of the matrix in a single-dimensional array.

##### Definition/Editing Sheet
Convolution2D operators have a Convolution2D sheet for definition and editing.  See the section for this sheet for more information.

#### Pooling
##### Operation Definition
A Pooling operator can process any data size.  The operator 'pools' the data from a rectangular volume down to a single 'pixel'.  The reduction size is specified as part of the operator, with each dimension of the input data being reduced by a specified amount.  The data in the cell is aggregated using a selectable function, either an average, minimum, or maximum of the data in the cell.

##### Network Operator Table Information
A Pooling operator appears in the Network Operator table with a type of "Pooling" and details giving the pooling type (average, minimum, or maximum), and the reduction factor for each dimension.

##### Definition/Editing Sheet
Pooling operators have a Pooling sheet for definition and editing.  See the section for this sheet for more information.

#### FeedForwardNN
##### Operation Definition
A Feed-Forward Neural Network operator can process any data size, but treats it as a single linear vector.  The operator multiplies each input value by a learnable weight value and sums the results.  This summation is then processed through a selectable activation function, effectively 'squashing' the summation to a managable value range.  This is done for a definable number of neural network nodes in the operator.  The nodes can be specified to be treated as a set of a specified dimension and size.  The output is presented as a vector, array, volume, or 4-dimensional solid of dimensions matching the node sizing for the operator.

##### Network Operator Table Information
A Neural Network operator appears in the Network Operator table with a type of "FeedForward NN" and details giving the activation function for the network and the resulting data size (based on the number of nodes in the network).

##### Definition/Editing Sheet
FeedForward Neural Network operators have a Neural Network sheet for definition and editing.  See the section for this sheet for more information.

#### NonLinearity
##### Operation Definition
A NonLinearity operator can process any data size, but treats it as a single linear vector.  The operator performs the selected non-linearity activation function on each element of the input, resulting in an output of the same size.

##### Network Operator Table Information
A NonLinearity operator appears in the Network Operator table with a type of "NonLinearity" and details giving the activation function for the operation.

##### Definition/Editing Sheet
NonLinearity operators use the Neural Network sheet for definition and editing, with the result size disabled, leaving just the activation function.  See the section for this sheet for more information.


##  Menu commands
##### Convolution->Quit
- Closes the application.  It will NOT ask to save work, even if something was modified.

##### File->Open
- Loads a network model, training parameters, and input definitions from a previously saved file.  Testing image sets identifiers are not saved or loaded.

##### File->Save
- Saves a network model, training parameters, and input definitions to a file.  The file is a standard plist file (a subset of XML), so it can be examined and possibly modified.

##### Network->Initialize
- All trainable parameters in the model are re-initialized to random values.

##### Network->Gradient Check
- A numeric check of the gradient calculations within the network is performed.  A success or failure message is displayed.

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
- The 'Add' button underneath the operator list activates the appropriate sheet for defining a new operator for the selected channel.  The type of sheet opened is set by the operator type selection to the right of the Add button.  See the section for the approprate sheet for use information.  The order of operators in the list determines the order that the operations are performed when the channel is processed.

##### Operator Type Selection
- This drop-down list contains all of the currently defined operators that can be added to a channel in a deep network.  See the Network Operators section of this manual for information on the currently known types.

##### Edit Button
- The 'Edit' button underneath the operator list is not currently functional.

##### Delete Button
- The 'Delete' button underneath the operator list removes the operator that is currently selected from the channel.


#### Neural Network Output
##### Output List
- The output list shows the output of the last operator of the last channel of the last layer in the deep network.  This output is used to determine the output class computed by the network.

##### Resulting Class
- This text field shows the resulting class calculated by the deep neural network for the current test/training image.  This class is extracted from the outputs of the last operator of the last channel of the last layer.  If the operator has only one floating value output, that value is compared against the middle of the expected output range for the operator, and if above that value a class of 1 is given, else a class of 0 is the result.  If the operator has more than one output value, the class is given as the index of the output with the highest value.


#### Topology Error
- This text field shows the status of the deep network configuration, listing any errors in the definition that must be corrected before the network can be trained or used.  The following strings may be seen in the field:
    * Valid Network - indicates the network is correctly configured, and may be used.
    * Empty Network - indicates the network has no layers to verify.
    * Layer <index>, channel <ID> uses input <sourceID>, which does not exist - the layer at the given index has a channel with the specified ID string that uses data tagged with the specified source ID tag, and that tag does not exist in the previous layer, or in the input sets if the layer index is 0.


#### Data Image
- This image view shows the selected data, either the train/test image, one of the image data sets as a greyscale pseudo-image, or the output of a selected operator (in the Network Operators list) as a greyscale pseudo-image.
##### Image Source
- The image source section provides a set of three radio buttons and a drop-down selection list to use in specifying the image shown in the image view.
    * Test Image - if selected, the testing or training image is shown in the image view, in full color.
    * Image Data - if selected, the image data of the type selected in the drop-down list to the right of the radio button is extracted from testing or training image, and then presented in the image view as a grayscale image at the same resolution as the source image.
    * Selected Item Output - if selected, the output of the selected network operator is shown as grayscale image of a resolution matching the output of the network operator.  If no operator is selected, or if the operator does not have a 2-dimensional output, the image view will show 'No Image'.


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


##  2D Convolution Sheet
The 2D convolution sheet is used to add or modify a convolution operation.  The following sections describe the entries in the sheet
#### 2D Convolution Type
- This drop-down list selects the type of 2-dimensional convolution that will be performed, both the size of the convolution matrix, and the (initial) entries of the matrix itself.  Changing the type will initialize the matrix entries on the sheet to the values expected for the selected matrix.  See the section on 2D Convolution Matrix Types for information on the selections available.

#### Convolution Matrix
- This set of entries define the initial values of the convolution matrix.  The matrix array will only have enterable fields in the size specified by the convolution type, centered in the sheet.  Changing any of the values will convert the matrix type to a 'custom' matrix of the current size.


##  2D Convolution Matrix Types
1. Vertical Edge 3x3 - A vertical gradient Sobel type filter
2. Horizontal Edge 3x3 - A horizontal gradient Sobel type filter
3. Custom 3x3 - A user-supplied 3x3 matrix
4. Learnable 3x3 - A 3x3 matrix that has values that will be learned from the error gradient


##  Experiments
1. Horizontal lines - learns to discriminate between horizontal and vertical lines
    - File->Open the Test1_Horizontal file.  This is a simple network with one channel.  A convolution of horizontal gradient, pooling down to 16 squares using maximum, and a two-layer neural net with 4 and 1 nodes respectively
    - Select the HorizontalTest file from the HorizontalTest directory for testing (your path will differ from mine)
    - Leave repeat training and Auto testing on.
    - Click 'Train'
    - The network should fairly quickly learn the horizontal lines, getting a 100% test rate in under a minute.  If you continue, the training error will continue down, while the test error goes up!  A classic case of 'overfitting'!
    
2. Circles and Lines - learns to discriminate between horizontal lines and circles using a trainable convolution operator
    - File->Open the Test2_Circle file.  This is a simple network with one channel.  A trainable convolution operator, pooling down to 16 squares using maximum, and a two-layer neural net with 4 and 1 nodes respectively.
    - This example uses generated images, so no paths need to be set
    - Leave repeat training on.
    - For speedier training, turn off 'Auto test'
    - Click 'Train'
    - When the training error starts to go down (gets below 40 sometimes) turn auto testing back on to see the test percentage start to creep up into the 90s.  Since images are all generated on the fly, there are a near-infinite number of variations, so we will likely never get a perfect score.
    - The network should medium quickly learn the differences, getting a about 95% test rate in about 5 minutes.
    



## License

This program is made available with the [Apache license](LICENSE.md).


