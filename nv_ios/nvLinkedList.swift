//
//  LinkedList.swift
//  cavDataStructures
//
//  Created by compass-362 on 28/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//
import Foundation

public class LNode<T> {
    var val : T!
    var link : LNode!
    var prev : LNode!
}

public class nvLinkedList<T> {
    private let dispatch_group = DispatchGroup();
    private var top,bottom,current : LNode<T>! ;
    private var LLsize : Int64;
    public init(){
        top = nil;
        bottom = nil;
        LLsize = 0;
    }
    public func isEmpty() -> Bool {
        if LLsize == 0 {
            return true;
        }
        return false;
    }
    
    public func size() -> Int64{
        return LLsize;
    }
    
    public func push_bottom(ele : T){
        dispatch_group.enter();
        if(LLsize == 0) {
            top = LNode<T>();
            top.val = ele;
            bottom=top;
            LLsize += 1;
        }
        else{
            let newLNode : LNode <T> = LNode<T>();
            newLNode.val = ele;
            newLNode.prev = bottom;
            newLNode.link = nil;
            bottom.link = newLNode;
            bottom = newLNode;
            LLsize += 1;
        }
        dispatch_group.leave();
    }
    
    public func push_top(ele : T){
        dispatch_group.enter();
        if(LLsize == 0) {
            top = LNode<T>();
            top.val = ele;
            bottom=top;
            LLsize += 1;
        }
        else{
            let newLNode : LNode <T> = LNode<T>();
            newLNode.val = ele;
            newLNode.link = top;
            newLNode.prev = nil;
            top = newLNode;
            LLsize += 1;
            
        }
        dispatch_group.leave();
    }
    
    public func getNext(fromTop : Bool=false, deleteCurrent : Bool=false) -> T? {
        if(deleteCurrent && current != nil) {// we have to check for current!=nil
            NSLog("[NetVision][NvLinkedList]  current is not nil now deleting current")
            var node = current;
            current = current.link;
            
            self.remove(node: &node)
        }
        if(fromTop){ if(LLsize != 0) {self.current = top; return top.val;}}
        else {
            if(self.current != nil && self.hasNext(node: self.current)/*|| self.current.link == nil || self.current.link.val == nil*/){
                self.current = self.current.link;
                return self.current.val;
            }
        }
        return nil;
    }
    
    public func clear(){
        dispatch_group.enter();
        while( LLsize > 0){
            pop();
        }
        dispatch_group.leave();
    }
    
    public func pop(){
        dispatch_group.enter();
        if(LLsize == 0){
            dispatch_group.leave();
            return;
        }
        else if( LLsize == 1){
            top = nil;
            bottom = nil;
            LLsize -= 1;
        }
        else{
            top = top.link;
            LLsize -= 1;
        }
        dispatch_group.leave();
    }
    
    public func ElementAtTop() -> T? {
        dispatch_group.enter();
        if( LLsize == 0 || top == nil){
            return nil;
        }
        var topEle :T = top.val;
        dispatch_group.leave();
        return topEle;
    }
    
    public func NodeAtTop() -> LNode<T>? {
        if(LLsize == 0){
            return nil;
        }
        else {
            return top;
        }
    }
    
    public func hasNext<T>(node : LNode<T>) -> Bool {
        if(LLsize == 0){
            return false;
        }
        else {
            if(node.link != nil){
                return true;
            }
            return false;
        }
    }

    public func remove<T>( node :inout LNode<T>?) -> Bool {
        dispatch_group.enter();
        if(node!.prev != nil) {
            node!.prev.link = node!.link;
        }
        else {
            top = top.link;
        }
        if node!.link == nil {
            bottom = bottom.prev;
        }
        else {
            node!.link!.prev = node!.prev;
        }
        node = nil;
        LLsize = LLsize - 1;
        dispatch_group.leave();
        return true;
    }
    
}
