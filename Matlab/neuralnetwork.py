""" Multilayer Perceptron.
A Multilayer Perceptron (Neural Network) implementation example using
TensorFlow library. This example is using the MNIST database of handwritten
digits (http://yann.lecun.com/exdb/mnist/).
Links:
    [MNIST Dataset](http://yann.lecun.com/exdb/mnist/).
Author: Aymeric Damien
Project: https://github.com/aymericdamien/TensorFlow-Examples/
"""

# ------------------------------------------------------------------
#
# THIS EXAMPLE HAS BEEN RENAMED 'neural_network.py', FOR SIMPLICITY.
#
# ------------------------------------------------------------------

from __future__ import print_function

# -----------
# Import data
# -----------

import csv
import numpy as np

images = []
labels = []

with open('images.csv', newline='') as imgFile:
    imgRead = csv.reader(imgFile, delimiter=' ', quotechar='|')
    for row in imgRead:
        row = row[0].split(',')
        for e in row:
            newrow += [float(e)/512]
        images += [newrow]
        newrow = []
        
images = np.float32(images)
        
with open('labels.csv', newline='') as labelFile:
    labelRead = csv.reader(labelFile, delimiter=' ', quotechar='|')
    for row in labelRead:
        row = row[0].split(',')
        for e in row:
            newrow += [float(e)]
        labels += [newrow]
        newrow = []      

labels = np.float32(labels)  

# --------------
# Neural Network
# --------------

# Import MNIST data
#from tensorflow.examples.tutorials.mnist import input_data
#mnist = input_data.read_data_sets("/tmp/data/", one_hot=True)

import tensorflow as tf

# Parameters
learning_rate = 0.007
training_epochs = 3000
batch_size = 224
display_step = 50

# Network Parameters
n_hidden_1 = 15 # 1st layer number of neurons
n_hidden_2 = 15 # 2nd layer number of neurons
n_hidden_3 = 15 # 2nd layer number of neurons
#n_input = 784 # MNIST data input (img shape: 28*28)
n_input = 256 # MNIST data input (img shape: 28*28)
n_classes = 10 # MNIST total classes (0-9 digits)

# tf Graph input
X = tf.placeholder("float", [None, n_input])
Y = tf.placeholder("float", [None, n_classes])

# Store layers weight & bias
weights = {
    'h1': tf.Variable(tf.random_normal([n_input, n_hidden_1]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25)),
    'h2': tf.Variable(tf.random_normal([n_hidden_1, n_hidden_2]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25)),
    'h3': tf.Variable(tf.random_normal([n_hidden_2, n_hidden_3]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25)),
    'out': tf.Variable(tf.random_normal([n_hidden_5, n_classes]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25))
}
biases = {
    'b1': tf.Variable(tf.random_normal([n_hidden_1]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25)),
    'b2': tf.Variable(tf.random_normal([n_hidden_2]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25)),
    'b3': tf.Variable(tf.random_normal([n_hidden_3]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25)),    
    'out': tf.Variable(tf.random_normal([n_classes]),constraint=lambda t: tf.clip_by_value(t, -0.25, 0.25))
}


# Create model
def multilayer_perceptron(x):
    # Hidden fully connected layer with 256 neurons
    layer_1 = tf.add(tf.matmul(x, weights['h1']), biases['b1'])
    # Hidden fully connected layer with 256 neurons
    layer_2 = tf.add(tf.matmul(layer_1, weights['h2']), biases['b2'])
    # Hidden fully connected layer with 256 neurons
    layer_3 = tf.add(tf.matmul(layer_2, weights['h3']), biases['b3'])
    # Output fully connected layer with a neuron for each class
    out_layer = tf.matmul(layer_3, weights['out']) + biases['out']
    return out_layer

# Construct model
logits = multilayer_perceptron(X)

# Define loss and optimizer
loss_op = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(
    logits=logits, labels=Y))
optimizer = tf.train.AdamOptimizer(learning_rate=learning_rate)
train_op = optimizer.minimize(loss_op)
# Initializing the variables
init = tf.global_variables_initializer()

with tf.Session() as sess:
    sess.run(init)

    # Training cycle
    for epoch in range(training_epochs):
        avg_cost = 0.
        total_batch = int(len(images)/batch_size)
        # Loop over all batches
        for i in range(total_batch):
            #batch_x, batch_y = mnist.train.next_batch(batch_size)
            batch_x = images[batch_size*i:batch_size*i+100]
            batch_y = labels[batch_size*i:batch_size*i+100]
            
            # Run optimization op (backprop) and cost op (to get loss value)
            _, c = sess.run([train_op, loss_op], feed_dict={X: batch_x, Y: batch_y})
            newWeights = [weights['h1'].eval(), weights['h2'].eval(), weights['h3'].eval(), weights['out'].eval()]
            newBiases = [biases['b1'].eval(), biases['b2'].eval(), biases['b3'].eval(), biases['out'].eval()]
            # Compute average loss
            avg_cost += float(c / total_batch)
        # Display logs per epoch step
        if epoch % display_step == 0:
            print("Epoch:", '%04d' % (epoch+1), "cost={:.9f}".format(avg_cost))
    print("Optimization Finished!")

    # Test model
    pred = tf.nn.relu(logits)  # Apply relu to logits
    correct_prediction = tf.equal(tf.argmax(pred, 1), tf.argmax(Y, 1))
    # Calculate accuracy
    accuracy = tf.reduce_mean(tf.cast(correct_prediction, "float"))
    #print("Accuracy:", accuracy.eval({X: mnist.test.images, Y: mnist.test.labels}))
    print("Accuracy:", accuracy.eval({X: images, Y: labels}))
    #d = ({X: images, Y: labels})
    #np.savetxt('images.txt', images, delimiter='   ')
    #np.savetxt('labels.txt', labels, delimiter='   ')
    np.savetxt('w0.txt', newWeights[0], delimiter='   ')
    np.savetxt('w1.txt', newWeights[1], delimiter='   ')
    np.savetxt('w2.txt', newWeights[2], delimiter='   ')
    np.savetxt('w3.txt', newWeights[3], delimiter='   ')
    np.savetxt('b0.txt', newBiases[0], delimiter='   ')
    np.savetxt('b1.txt', newBiases[1], delimiter='   ')
    np.savetxt('b2.txt', newBiases[2], delimiter='   ')
    np.savetxt('b3.txt', newBiases[3], delimiter='   ')